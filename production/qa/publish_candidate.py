#!/usr/bin/env python3
"""Publish an explicitly authorized judging pre-release from a successful native CI run.

Requires GitHub CLI authentication with actions:read and contents:write. Existing
releases/assets are preserved; this command never replaces an asset or final release.
"""
import argparse
import json
from pathlib import Path
import re
import subprocess
import tempfile
import zipfile

from build_release import sha256_file, validate_package, runtime_hashes

ROOT = Path(__file__).resolve().parents[2]
REPO = 'SadManQT/nasa-space-apps-2026'


def gh_json(path, missing_ok=False):
    result = subprocess.run(['gh', 'api', 'repos/' + REPO + path], text=True, capture_output=True)
    if result.returncode:
        if missing_ok and 'HTTP 404' in result.stderr:
            return None
        raise RuntimeError(result.stderr)
    return json.loads(result.stdout)


def verify_manifest(manifest, package, source, kind):
    if manifest.get('source_commit') != source or manifest.get('platform') != kind:
        raise RuntimeError('Candidate source/platform does not match the successful CI run')
    if manifest.get('smoke') not in ('headless', 'windowed'):
        raise RuntimeError('Candidate did not run packaged startup checks')
    expected = manifest.get('package', {})
    if expected.get('name') != package.name or expected.get('bytes') != package.stat().st_size:
        raise RuntimeError('Candidate artifact name/size mismatch')
    if expected.get('sha256') != sha256_file(package):
        raise RuntimeError('Candidate package digest mismatch')
    validate_package(package, kind)
    if manifest.get('runtime_files_sha256') != runtime_hashes(package):
        raise RuntimeError('Candidate runtime identity manifest mismatch')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run-id', required=True, type=int)
    parser.add_argument('--tag', required=True)
    parser.add_argument('--notes-file', type=Path, required=True)
    parser.add_argument('--evidence', type=Path, action='append', default=[])
    args = parser.parse_args()
    if not re.fullmatch(r'v0\.1\.0-judging\.\d{8}', args.tag):
        raise RuntimeError('Only dated judging pre-release tags are accepted')
    if not args.notes_file.is_file() or not args.notes_file.read_text().strip():
        raise RuntimeError('A concrete reviewed release description is required')
    run = gh_json('/actions/runs/' + str(args.run_id))
    if run['conclusion'] != 'success' or run['path'].split('@')[0] != '.github/workflows/judging-candidate.yml':
        raise RuntimeError('Both native candidate jobs must pass in the expected workflow')
    source = run['head_sha']
    if not re.fullmatch(r'[0-9a-f]{40}', source):
        raise RuntimeError('Invalid frozen source revision')
    subprocess.run(['git', 'diff', '--exit-code', source, 'HEAD', '--', 'game'], cwd=ROOT, check=True)
    with tempfile.TemporaryDirectory(prefix='lla-judging-publish-') as temp:
        staging = Path(temp)
        subprocess.run(['gh', 'run', 'download', str(args.run_id), '--repo', REPO, '--dir', str(staging)], check=True)
        packages = []
        manifests = []
        for kind in ('windows', 'macos'):
            directory = staging / ('judging-' + kind + '-' + source)
            manifest = json.loads((directory / kind / 'manifest.json').read_text())
            package = directory / manifest['package']['name']
            verify_manifest(manifest, package, source, kind)
            packages.append(package)
            manifests.append(manifest)
        sums = staging / 'SHA256SUMS.txt'
        sums.write_text(''.join(sha256_file(p) + '  ' + p.name + '\n' for p in packages))
        manifest_path = staging / 'candidate_manifest.json'
        manifest_path.write_text(json.dumps({'run_id': args.run_id, 'source_commit': source, 'candidates': manifests}, indent=2) + '\n')
        evidence = staging / 'last-light-academy-judging-evidence.zip'
        with zipfile.ZipFile(evidence, 'w', compression=zipfile.ZIP_DEFLATED) as bundle:
            for requested in args.evidence:
                path = requested.resolve()
                if not path.exists() or not path.is_relative_to(ROOT):
                    raise RuntimeError('Evidence must exist inside this checkout: ' + str(requested))
                for item in sorted(path.rglob('*')) if path.is_dir() else [path]:
                    if item.is_file():
                        bundle.write(item, item.relative_to(ROOT))
            for name in ('LICENSE', 'CREDITS.md', 'production/AI_PROMPT_LOG.md'):
                bundle.write(ROOT / name, name)
            bundle.write(manifest_path, manifest_path.name)
            bundle.write(sums, sums.name)
        release = gh_json('/releases/tags/' + args.tag, missing_ok=True)
        if release is not None and (not release['draft'] or not release['prerelease']):
            raise RuntimeError('An existing published release is preserved; choose a new authorized tag')
        if release is not None and release['target_commitish'] != source:
            raise RuntimeError('Existing draft targets another revision; preserving it')
        if release is None:
            subprocess.run(['gh', 'release', 'create', args.tag, '--repo', REPO, '--target', source,
                            '--draft', '--prerelease', '--title', 'Last Light Academy — judging candidate (12 November 2026)',
                            '--notes-file', str(args.notes_file.resolve())], check=True)
            release = gh_json('/releases/tags/' + args.tag)
        existing = {a['name']: a for a in release['assets']}
        for path in packages + [sums, manifest_path, evidence]:
            if path.name in existing:
                if existing[path.name].get('digest') != 'sha256:' + sha256_file(path):
                    raise RuntimeError('Existing asset differs; preserving it: ' + path.name)
                continue
            subprocess.run(['gh', 'release', 'upload', args.tag, str(path), '--repo', REPO], check=True)
        subprocess.run(['gh', 'release', 'edit', args.tag, '--repo', REPO, '--draft=false', '--prerelease',
                        '--latest=false', '--notes-file', str(args.notes_file.resolve())], check=True)
        print('Published verified judging candidate:', args.tag, 'source', source)


if __name__ == '__main__':
    main()
