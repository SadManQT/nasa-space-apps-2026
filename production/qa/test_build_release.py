"""Package integrity checks; these do not substitute for native boot evidence."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
import zipfile
from publish_candidate import verify_manifest

spec = importlib.util.spec_from_file_location('build_release', Path(__file__).with_name('build_release.py'))
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)
NOTICES = ['FONT_LICENSES/' + n for n in builder.FONT_NOTICES] + ['THIRD_PARTY_NOTICES/gohud/' + n for n in builder.GOHUD_NOTICES]


class PackageTests(unittest.TestCase):
    def package(self, root, names):
        path = root / 'candidate.zip'
        with zipfile.ZipFile(path, 'w') as bundle:
            for name in names:
                bundle.writestr(name, b'candidate test fixture')
        return path

    def test_missing_runtime_or_credits_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            complete = ['LICENSE', 'CREDITS.md', 'README.txt', 'LastLightAcademy.exe', 'LastLightAcademy.pck'] + NOTICES
            self.assertEqual(builder.validate_package(self.package(root, complete), 'windows'), len(complete))
            for missing in complete:
                with self.subTest(missing=missing), self.assertRaises(RuntimeError):
                    builder.validate_package(self.package(root, [n for n in complete if n != missing]), 'windows')

    def test_mac_requires_both_app_and_game_pack(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            complete = ['LICENSE', 'CREDITS.md', 'README.txt', 'Game.app/Contents/MacOS/Game', 'Game.app/Contents/Resources/Game.pck'] + NOTICES
            self.assertEqual(builder.validate_package(self.package(root, complete), 'macos'), len(complete))
            for missing in complete:
                with self.subTest(missing=missing), self.assertRaises(RuntimeError):
                    builder.validate_package(self.package(root, [n for n in complete if n != missing]), 'macos')

    def test_archive_cannot_extract_outside_destination(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            for name in ['../escaped', '/escaped', 'C:/escaped', '..\\escaped']:
                with self.subTest(name=name), self.assertRaises(RuntimeError):
                    builder.validate_package(self.package(root, [name]), 'windows')
            with self.assertRaises(RuntimeError):
                builder.extract(self.package(root, ['../escaped']), root / 'unpacked')
            self.assertFalse((root / 'escaped').exists())

    def test_digest_changes_when_artifact_changes(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / 'artifact'
            path.write_bytes(b'abc')
            self.assertEqual(builder.sha256_file(path), 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad')
            path.write_bytes(b'abd')
            self.assertNotEqual(builder.sha256_file(path), 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad')

    def test_publisher_rejects_other_source_or_tampered_package(self):
        with tempfile.TemporaryDirectory() as temp:
            path = self.package(Path(temp), ['LICENSE', 'CREDITS.md', 'README.txt', 'LastLightAcademy.exe', 'LastLightAcademy.pck'] + NOTICES)
            manifest = {'source_commit': 'a' * 40, 'platform': 'windows', 'smoke': 'headless',
                        'runtime_files_sha256': builder.runtime_hashes(path),
                        'package': {'name': path.name, 'bytes': path.stat().st_size, 'sha256': builder.sha256_file(path)}}
            verify_manifest(manifest, path, 'a' * 40, 'windows')
            with self.assertRaises(RuntimeError):
                verify_manifest(manifest, path, 'b' * 40, 'windows')
            manifest['smoke'] = 'not_run'
            with self.assertRaises(RuntimeError):
                verify_manifest(manifest, path, 'a' * 40, 'windows')
            manifest['smoke'] = 'headless'
            manifest['package']['sha256'] = '0' * 64
            with self.assertRaises(RuntimeError):
                verify_manifest(manifest, path, 'a' * 40, 'windows')

    def test_runtime_identity_ignores_distribution_document_changes(self):
        with tempfile.TemporaryDirectory() as temp:
            path = self.package(Path(temp), ['LastLightAcademy.exe', 'LastLightAcademy.pck', 'README.txt'])
            before = builder.runtime_hashes(path)
            with zipfile.ZipFile(path, 'a') as bundle:
                bundle.writestr('FONT_LICENSES/OFL_Inter.txt', 'Supplied font license')
            self.assertEqual(builder.runtime_hashes(path), before)
            self.assertEqual(set(before), {'LastLightAcademy.exe', 'LastLightAcademy.pck'})


if __name__ == '__main__':
    unittest.main()
