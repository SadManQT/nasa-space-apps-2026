#!/usr/bin/env python3
"""Reproduce and smoke-test a native candidate without an editor session.

GODOT=/path/to/Godot python3 production/qa/build_release.py --platform macos --smoke
python3 production/qa/build_release.py --platform windows --install-tools --smoke
"""
import argparse, hashlib, json, os, pathlib, platform, re, shutil, subprocess, tempfile, urllib.request, zipfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
VERSION = '4.7.2'
BASE = f'https://github.com/godotengine/godot-builds/releases/download/{VERSION}-stable/'
FONT_NOTICES = ('OFL_Inter.txt', 'OFL_Saira.txt')
GOHUD_NOTICES = ('LICENSE', 'THIRD_PARTY_NOTICES.md',
                 'assets/fonts/cinzel/OFL.txt', 'assets/fonts/roboto/OFL.txt',
                 'assets/fonts/nunito/OFL.txt', 'assets/fonts/noto_sans_cjk/OFL.txt')

def sha256_file(path):
    digest = hashlib.sha256()
    with pathlib.Path(path).open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()

def validate_package(package, kind):
    with zipfile.ZipFile(package) as bundle:
        if bundle.testzip() is not None:
            raise RuntimeError('Package CRC verification failed')
        names = bundle.namelist()
        for name in names:
            path = pathlib.PurePosixPath(name.replace('\\', '/'))
            if path.is_absolute() or '..' in path.parts or (path.parts and ':' in path.parts[0]):
                raise RuntimeError('Unsafe package path: ' + name)
        notices = {'FONT_LICENSES/' + name for name in FONT_NOTICES}
        notices.update('THIRD_PARTY_NOTICES/gohud/' + name for name in GOHUD_NOTICES)
        if not ({'LICENSE', 'CREDITS.md', 'README.txt'} | notices).issubset(names):
            raise RuntimeError('Package is missing credits, license, font notices or launch instructions')
        if kind == 'windows':
            runtime = 'LastLightAcademy.exe' in names and 'LastLightAcademy.pck' in names
        else:
            runtime = any('.app/Contents/MacOS/' in n and not n.endswith('/') for n in names) and any(n.endswith('.pck') for n in names)
        if not runtime:
            raise RuntimeError('Package is missing its executable or game pack')
        return len(names)

def runtime_hashes(package):
    result = {}
    with zipfile.ZipFile(package) as bundle:
        for entry in bundle.infolist():
            name = entry.filename
            if entry.is_dir() or not ('.app/' in name or name.endswith(('.exe', '.pck', '.dll'))):
                continue
            digest = hashlib.sha256()
            with bundle.open(entry) as stream:
                for block in iter(lambda: stream.read(1024 * 1024), b''):
                    digest.update(block)
            result[name] = digest.hexdigest()
    return result

def download(name, directory):
    target = directory / name
    if not target.exists():
        print('Download', name, flush=True)
        urllib.request.urlretrieve(BASE + name, target)
    return target

def extract(archive, directory, names=None):
    with zipfile.ZipFile(archive) as bundle:
        for entry in bundle.infolist():
            if names is not None and entry.filename not in names:
                continue
            target = directory / entry.filename
            if directory.resolve() not in target.resolve().parents:
                raise RuntimeError('Archive path escapes destination')
            if entry.is_dir():
                target.mkdir(parents=True, exist_ok=True)
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(bundle.read(entry))
                mode = entry.external_attr >> 16
                if mode:
                    target.chmod(mode)

def install_tools(kind):
    cache = pathlib.Path(tempfile.gettempdir()) / 'last-light-release-tools'
    cache.mkdir(parents=True, exist_ok=True)
    system = platform.system()
    if system == 'Darwin':
        archive = download(f'Godot_v{VERSION}-stable_macos.universal.zip', cache)
        extract(archive, cache)
        engine = cache / 'Godot.app/Contents/MacOS/Godot'
        templates = pathlib.Path.home() / 'Library/Application Support/Godot/export_templates'
    elif system == 'Windows':
        archive = download(f'Godot_v{VERSION}-stable_win64.exe.zip', cache)
        extract(archive, cache)
        engine = cache / f'Godot_v{VERSION}-stable_win64_console.exe'
        templates = pathlib.Path(os.environ['APPDATA']) / 'Godot/export_templates'
    else:
        raise RuntimeError('Native clean-machine smoke supports Windows and macOS')
    archive = download(f'Godot_v{VERSION}-stable_export_templates.tpz', cache)
    required = ['macos.zip'] if kind == 'macos' else ['windows_release_x86_64.exe', 'windows_release_x86_64_console.exe']
    destination = templates / f'{VERSION}.stable'
    destination.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive) as bundle:
        for name in required + ['version.txt']:
            (destination / name).write_bytes(bundle.read('templates/' + name))
    return str(engine)

def run_checked(command, log, cwd, timeout=900, result_pattern=None, ignore=None):
    result = subprocess.run([str(x) for x in command], cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=timeout)
    log.write_text(result.stdout, encoding='utf-8')
    errors = re.findall(r'(?:SCRIPT ERROR|Parse Error|^ERROR:).*', result.stdout, re.MULTILINE)
    if ignore:
        errors = [e for e in errors if not re.search(ignore, e)]
    if result.returncode != 0 or errors or (result_pattern and not re.search(result_pattern, result.stdout)):
        print(result.stdout[-16000:])
        raise RuntimeError(f'{log.name}: exit {result.returncode}, errors={errors[:4]}')
    print('\n'.join(line for line in result.stdout.splitlines() if 'RESULT:' in line or '_READY_MS' in line), flush=True)
    return result.stdout

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--platform', required=True, choices=['windows', 'macos'])
    parser.add_argument('--install-tools', action='store_true')
    parser.add_argument('--smoke', action='store_true')
    parser.add_argument('--evidence', action='store_true')
    parser.add_argument('--output-root', type=pathlib.Path, default=ROOT / 'builds/2026-11-04',
                        help='Separate candidate output directory; refuses an existing package')
    args = parser.parse_args()
    output = args.output_root.resolve() / args.platform
    package = output.parent / ('last-light-academy-0.1.0-' + args.platform + '.zip')
    if package.exists() or (output.exists() and any(output.iterdir())):
        raise RuntimeError('Use a new output root; existing build evidence is preserved: ' + str(output))
    engine = install_tools(args.platform) if args.install_tools else os.environ.get('GODOT', shutil.which('godot') or '/Applications/Godot.app/Contents/MacOS/Godot')
    version = subprocess.check_output([engine, '--version'], text=True).strip()
    if not version.startswith(VERSION + '.'):
        raise RuntimeError('Expected the pinned Godot 4.7.2, got ' + version)
    output.mkdir(parents=True, exist_ok=True)
    filename = output / ('LastLightAcademy.exe' if args.platform == 'windows' else 'LastLightAcademy.zip')
    preset = 'Windows x86_64' if args.platform == 'windows' else 'macOS Universal unsigned'
    # A fresh checkout imports every asset first. Under the headless dummy renderer one
    # model's import script logs a harmless 'Parameter "t" is null' texture error, so the
    # import runs as its own step (exit code checked); the export after it is held to
    # the strict no-ERROR rule.
    imported = subprocess.run([str(engine), '--headless', '--path', str(ROOT / 'game'), '--import'], cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=1800)
    (output / 'import.log').write_text(imported.stdout, encoding='utf-8')
    if imported.returncode != 0:
        print(imported.stdout[-8000:])
        raise RuntimeError(f'import.log: exit {imported.returncode}')
    # The editor process that runs the export reports its own leftovers when it quits
    # (seen on the Windows runner); that is not an export error. The game smoke below
    # keeps the strict rule.
    run_checked([engine, '--headless', '--path', ROOT / 'game', '--export-release', preset, filename], output / 'export.log', ROOT, ignore=r'resources still in use at exit')
    if args.smoke:
        if args.platform == 'macos':
            extracted = output / 'unpacked'
            extract(filename, extracted)
            executable = next(extracted.glob('*.app/Contents/MacOS/*'))
        else:
            executable = output / 'LastLightAcademy.console.exe'
            if not executable.exists():
                executable = filename
        command = [executable]
        if not args.evidence:
            command.append('--headless')
        command.extend(['--', '--export-smoke'])
        if args.evidence:
            command.extend(['--evidence-dir=' + str(ROOT / 'production/qa/evidence')])
        with tempfile.TemporaryDirectory(prefix='lla-export-smoke-') as outside_project:
            run_checked(command, output / 'smoke.log', outside_project, timeout=180, result_pattern=r'EXPORT SMOKE RESULT: PASS \(\d+ checks, 0 failures\)')
    (output / 'README.txt').write_text(
        'Last Light Academy — ' + re.search(r'config/version="([^"]+)"', (ROOT / 'game/project.godot').read_text()).group(1) + '\n'
        'The Last BrainCell / NASA Space Apps 2026 independent team project.\n'
        'Windows: keep the EXE and PCK together; run LastLightAcademy.exe.\n'
        'macOS: unzip the app and open it. This team build is unsigned and unnotarized.\n'
        'If blocked, use System Settings > Privacy & Security > Open Anyway for this app.\n'
        'WASD: move; mouse: look while walking; E: use nearby operation.\n'
        'Tab/arrows/Enter: UI; Escape: pause. Captions and large text are in Settings.\n'
        'Source, AI disclosure and QA: https://github.com/SadManQT/nasa-space-apps-2026\n'
        'This is a development candidate; the repository board tracks remaining work.\n', encoding='utf-8')
    for name in ['LICENSE', 'CREDITS.md']:
        shutil.copy2(ROOT / name, output / name)
    with zipfile.ZipFile(package, 'w', compression=zipfile.ZIP_DEFLATED) as bundle:
        if args.platform == 'macos':
            with zipfile.ZipFile(filename) as app_archive:
                for entry in app_archive.infolist():
                    bundle.writestr(entry, app_archive.read(entry))
        else:
            for native in output.iterdir():
                if native.suffix in ['.exe', '.pck', '.dll']:
                    bundle.write(native, native.name)
        for name in ['LICENSE', 'CREDITS.md', 'README.txt']:
            bundle.write(output / name, name)
        for name in FONT_NOTICES:
            bundle.write(ROOT / 'game/assets/fonts/ui' / name, 'FONT_LICENSES/' + name)
        for name in GOHUD_NOTICES:
            bundle.write(ROOT / 'game/addons/gohud' / name, 'THIRD_PARTY_NOTICES/gohud/' + name)
    entry_count = validate_package(package, args.platform)
    source = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    game_changes = subprocess.check_output(['git', 'diff', '--name-only', 'HEAD', '--', 'game'], cwd=ROOT, text=True).splitlines()
    manifest = {'source_commit': source, 'platform': args.platform, 'engine': version,
                'game_version': re.search(r'config/version="([^"]+)"', (ROOT / 'game/project.godot').read_text()).group(1),
                'game_tracked_changes_after_import': game_changes,
                'smoke': 'windowed' if args.smoke and args.evidence else 'headless' if args.smoke else 'not_run',
                'package': {'name': package.name, 'bytes': package.stat().st_size,
                            'sha256': sha256_file(package), 'entries': entry_count},
                'runtime_files_sha256': runtime_hashes(package),
                'logs': {p.name: sha256_file(p) for p in output.glob('*.log')}}
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    (output / 'SHA256SUMS.txt').write_text(manifest['package']['sha256'] + '  ' + package.name + '\n', encoding='utf-8')
    print('PACKAGE', package.name, package.stat().st_size, manifest['package']['sha256'], flush=True)
    print('BUILD RESULT:', args.platform, 'PASS', 'sha256', sha256_file(filename), flush=True)

if __name__ == '__main__':
    main()
