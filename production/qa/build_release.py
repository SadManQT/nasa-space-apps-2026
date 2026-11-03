#!/usr/bin/env python3
"""Reproduce and smoke-test a native candidate without an editor session.

GODOT=/path/to/Godot python3 production/qa/build_release.py --platform macos --smoke
python3 production/qa/build_release.py --platform windows --install-tools --smoke
"""
import argparse, hashlib, os, pathlib, platform, re, shutil, subprocess, tempfile, urllib.request, zipfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
VERSION = '4.7.2'
BASE = f'https://github.com/godotengine/godot-builds/releases/download/{VERSION}-stable/'

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

def run_checked(command, log, cwd, timeout=900, result_pattern=None):
    result = subprocess.run([str(x) for x in command], cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=timeout)
    log.write_text(result.stdout, encoding='utf-8')
    errors = re.findall(r'(?:SCRIPT ERROR|Parse Error|^ERROR:).*', result.stdout, re.MULTILINE)
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
    args = parser.parse_args()
    engine = install_tools(args.platform) if args.install_tools else os.environ.get('GODOT', shutil.which('godot') or '/Applications/Godot.app/Contents/MacOS/Godot')
    version = subprocess.check_output([engine, '--version'], text=True).strip()
    if not version.startswith(VERSION + '.'):
        raise RuntimeError('Expected the pinned Godot 4.7.2, got ' + version)
    output = ROOT / 'builds/2026-11-04' / args.platform
    output.mkdir(parents=True, exist_ok=True)
    filename = output / ('LastLightAcademy.exe' if args.platform == 'windows' else 'LastLightAcademy.zip')
    preset = 'Windows x86_64' if args.platform == 'windows' else 'macOS Universal unsigned'
    run_checked([engine, '--headless', '--path', ROOT / 'game', '--export-release', preset, filename], output / 'export.log', ROOT)
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
        'Last Light Academy — 0.1.0-preview.20261104\n'
        'The Last BrainCell / NASA Space Apps 2026 independent team project.\n'
        'Windows: keep the EXE and PCK together; run LastLightAcademy.exe.\n'
        'macOS: unzip the app and open it. This team build is unsigned and unnotarized.\n'
        'If blocked, use System Settings > Privacy & Security > Open Anyway for this app.\n'
        'WASD: move; hold right mouse button: look; E: use nearby operation.\n'
        'Tab/arrows/Enter: UI; Escape: pause. Captions and large text are in Settings.\n'
        'Source, AI disclosure and QA: https://github.com/SadManQT/nasa-space-apps-2026\n'
        'This is a development candidate; the repository board tracks remaining work.\n', encoding='utf-8')
    for name in ['LICENSE', 'CREDITS.md']:
        shutil.copy2(ROOT / name, output / name)
    package = output.parent / ('last-light-academy-0.1.0-' + args.platform + '.zip')
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
    with zipfile.ZipFile(package) as bundle:
        if bundle.testzip() is not None:
            raise RuntimeError('Package CRC verification failed')
    print('PACKAGE', package.name, package.stat().st_size, hashlib.sha256(package.read_bytes()).hexdigest(), flush=True)
    print('BUILD RESULT:', args.platform, 'PASS', 'sha256', hashlib.sha256(filename.read_bytes()).hexdigest(), flush=True)

if __name__ == '__main__':
    main()
