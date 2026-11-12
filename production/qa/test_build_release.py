"""Package integrity checks; these do not substitute for native boot evidence."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
import zipfile

spec = importlib.util.spec_from_file_location('build_release', Path(__file__).with_name('build_release.py'))
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


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
            complete = ['LICENSE', 'CREDITS.md', 'README.txt', 'LastLightAcademy.exe', 'LastLightAcademy.pck']
            self.assertEqual(builder.validate_package(self.package(root, complete), 'windows'), 5)
            for missing in complete:
                with self.subTest(missing=missing), self.assertRaises(RuntimeError):
                    builder.validate_package(self.package(root, [n for n in complete if n != missing]), 'windows')

    def test_mac_requires_both_app_and_game_pack(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            complete = ['LICENSE', 'CREDITS.md', 'README.txt', 'Game.app/Contents/MacOS/Game', 'Game.app/Contents/Resources/Game.pck']
            self.assertEqual(builder.validate_package(self.package(root, complete), 'macos'), 5)
            for missing in complete[-2:]:
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


if __name__ == '__main__':
    unittest.main()
