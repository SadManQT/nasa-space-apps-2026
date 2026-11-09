"""Regressions for the implementation-only team batch and file ownership."""
import copy
import unittest
import contextlib
import io
import json
import pathlib
import sys
import tempfile
from unittest.mock import patch

import board


class BatchBoardTests(unittest.TestCase):
    def setUp(self):
        self.data = {
            'milestones': [{'id': 'M1'}],
            'members': [{'id': n, 'share': 0} for n in ['ramim', 'asif', 'atik', 'tanvir', 'sadman', 'shanto']],
            'implementation_batch': {
                'id': 'test', 'active': True,
                'assignments': {'tanvir': ['M1-122'], 'shanto': ['M1-71']},
                'deferred_ids': ['M1-75'], 'acceptance_ids': [],
            },
            'tasks': [
                dict(id='M1-122', title='Garden collision repair', milestone='M1', priority='P0', tool='codex', status='todo',
                     deps=[], prompt='repair collision', owner='', reserved_for='tanvir', paths=['game/scripts/world/']),
                dict(id='M1-71', title='Save slots', milestone='M1', priority='P1', tool='codex', status='todo',
                     deps=[], prompt='save slots', owner='', reserved_for='shanto', paths=['game/scripts/save/'],
                     integration_paths=['game/scripts/world/room.gd']),
                dict(id='M1-75', title='Deferred review', milestone='M1', priority='P0', tool='codex', status='todo',
                     deps=[], prompt='later review', owner='', reserved_for='asif', paths=['production/review/']),
            ],
        }

    def test_only_explicit_active_ids_are_selectable(self):
        self.assertEqual([t['id'] for t in board.next_tasks(self.data, by='Tanvir/codex')], ['M1-122'])
        self.assertEqual(board.next_tasks(self.data, by='Asif/codex'), [])
        self.assertEqual({t['id'] for t in board.next_tasks(self.data)}, {'M1-122', 'M1-71'})
        self.assertFalse(board.allowed(self.data, self.data['tasks'][0], 'TanvirOther/codex'))
        self.assertFalse(board.allowed(self.data, self.data['tasks'][2], 'Asif/codex'))

    def test_missing_batch_task_is_not_silently_assigned(self):
        self.data['implementation_batch']['assignments']['asif'] = ['M1-404']
        self.assertTrue(any('M1-404' in p for p in board.validate(self.data)))

    def test_mismatched_member_is_rejected(self):
        self.data['tasks'][0]['reserved_for'] = 'sadman'
        self.assertTrue(any('M1-122' in p and 'tanvir' in p for p in board.validate(self.data)))

    def test_deferred_work_is_distinguished_from_dependencies(self):
        self.assertEqual(board.batch_phase(self.data, self.data['tasks'][2]), 'deferred')
        self.assertEqual(board.batch_phase(self.data, self.data['tasks'][0]), 'implementation')
        self.assertFalse(board.allowed(self.data, self.data['tasks'][0], 'Atik/codex'))

    def test_exact_file_lock_prevents_two_writers_without_locking_whole_folder(self):
        a, b = self.data['tasks'][:2]
        a.update(status='in_progress', owner='Tanvir/codex')
        b.update(status='in_progress', owner='Shanto/codex')
        self.assertEqual(board.reserve_files(self.data, 'M1-122', 'Tanvir/codex', ['game/scripts/world/room.gd']), [])
        self.assertTrue(board.reserve_files(self.data, 'M1-71', 'Shanto/codex', ['game/scripts/world/room.gd']))
        self.assertNotIn('edit_files', b)
        self.assertEqual(board.reserve_files(self.data, 'M1-71', 'Shanto/codex', ['game/scripts/save/slots.gd']), [])
        self.assertEqual(board.merge_risks(self.data), [])
        b['edit_files'] = ['GAME/scripts/world/room.gd']
        self.assertTrue(board.merge_risks(self.data))

    def test_invalid_or_out_of_scope_lock_is_atomic(self):
        a = self.data['tasks'][0]
        a.update(status='in_progress', owner='Tanvir/codex')
        for paths in [['../secret'], ['C:/secret'], ['game/scripts/save/slots.gd'], ['game/scripts/world/room.gd', '../bad']]:
            with self.subTest(paths=paths):
                before = copy.deepcopy(self.data)
                self.assertTrue(board.reserve_files(self.data, a['id'], 'Tanvir/codex', paths))
                self.assertEqual(self.data, before)
        self.assertTrue(board.reserve_files(self.data, a['id'], 'Atik/codex', ['game/scripts/world/room.gd']))

    def test_without_batch_legacy_board_still_selects_work(self):
        del self.data['implementation_batch']
        self.assertEqual([t['id'] for t in board.next_tasks(self.data, by='Asif/codex')], ['M1-75'])

    def run_cli(self, path, *args):
        output = io.StringIO()
        with patch.object(board, 'TASKS', path), patch.object(board, 'BOARD', path.with_suffix('.html')), \
             patch.object(sys, 'argv', ['board.py', *args]), contextlib.redirect_stdout(output):
            board.main()
        return output.getvalue()

    def test_cli_does_not_resume_or_claim_deferred_work(self):
        self.data['tasks'][2].update(status='in_progress', owner='Asif/codex')
        with tempfile.TemporaryDirectory() as folder:
            path = pathlib.Path(folder) / 'tasks.json'
            path.write_text(json.dumps(self.data), encoding='utf-8')
            before = path.read_bytes()
            self.assertIn('No tasks in progress', self.run_cli(path, 'mine', '--by', 'Asif/codex'))
            with self.assertRaisesRegex(SystemExit, 'outside the active implementation batch'):
                self.run_cli(path, 'claim', 'M1-75', '--by', 'Asif/codex')
            self.assertEqual(path.read_bytes(), before)

    def test_cli_claim_lock_handoff_keeps_only_one_writer(self):
        with tempfile.TemporaryDirectory() as folder:
            path = pathlib.Path(folder) / 'tasks.json'
            path.write_text(json.dumps(self.data), encoding='utf-8')
            self.run_cli(path, 'claim', 'M1-122', '--by', 'Tanvir/codex')
            self.run_cli(path, 'lock', 'M1-122', '--by', 'Tanvir/codex', '--files', 'game/scripts/world/room.gd')
            self.run_cli(path, 'claim', 'M1-71', '--by', 'Shanto/codex')
            before = path.read_bytes()
            with self.assertRaisesRegex(SystemExit, 'file reserved by M1-122'):
                self.run_cli(path, 'lock', 'M1-71', '--by', 'Shanto/codex', '--files', 'game/scripts/world/room.gd')
            self.assertEqual(path.read_bytes(), before)
            with self.assertRaisesRegex(SystemExit, 'only the task'):
                self.run_cli(path, 'unlock', 'M1-122', '--by', 'Shanto/codex')
            self.run_cli(path, 'unlock', 'M1-122', '--by', 'Tanvir/codex')
            self.run_cli(path, 'lock', 'M1-71', '--by', 'Shanto/codex', '--files', 'game/scripts/world/room.gd')
            saved = json.loads(path.read_text(encoding='utf-8'))
            self.assertNotIn('edit_files', saved['tasks'][0])
            self.assertEqual(saved['tasks'][1]['edit_files'], ['game/scripts/world/room.gd'])

    def test_actual_batch_matches_the_users_exact_assignments(self):
        expected = {
            'ramim': {'M3-61','M3-64','M3-62','M3-63','M3-65','M3-4P','M3-4U','M3-4M',
                      'M3-6P','M3-6U','M3-6M','M3-8P','M3-8U','M3-8M','M1-18','M1-31','M3-67','M3-72','M3-90','M3-91'},
            'sadman': {'M3-5P','M3-5U','M3-5M','M3-7P','M3-7U','M3-7M','M1-49','M3-95','M3-101','M1-108','M4-16'},
            'asif': {'M1-105','M3-2P','M3-2U','M3-2M','M1-103','M1-37','M3-3P','M3-3U','M3-3M','M3-69'},
            'atik': {'M1-68','M1-92','M1-53','M1-116'},
            'tanvir': {'M1-122','M1-123','M1-85'}, 'shanto': {'M3-71','M3-70'},
        }
        data = board.load()
        self.assertEqual({m: set(ids) for m, ids in data['implementation_batch']['assignments'].items()}, expected)
        self.assertEqual(len(data['implementation_batch']['deferred_ids']), 31)
        self.assertEqual(len(data['implementation_batch']['acceptance_ids']), 15)
        for member, ids in expected.items():
            self.assertTrue(all(t['id'] in ids for t in board.next_tasks(data, by=member+'/codex')))
        self.assertFalse(board.allowed(data, board.by_id(data)['M3-75'], 'Asif/codex'))

    def test_status_commands_cannot_clear_another_members_reservation(self):
        with tempfile.TemporaryDirectory() as folder:
            path = pathlib.Path(folder) / 'tasks.json'
            path.write_text(json.dumps(self.data), encoding='utf-8')
            self.run_cli(path, 'claim', 'M1-122', '--by', 'Tanvir/codex')
            self.run_cli(path, 'lock', 'M1-122', '--by', 'Tanvir/codex', '--files', 'game/scripts/world/room.gd')
            for command, extra in [('release', []), ('block', ['--reason', 'later']), ('done', ['--evidence', 'test pass'])]:
                for actor in [[], ['--by', 'Shanto/codex']]:
                    with self.subTest(command=command, actor=actor):
                        before = path.read_bytes()
                        with self.assertRaises(SystemExit):
                            self.run_cli(path, command, 'M1-122', *extra, *actor)
                        self.assertEqual(path.read_bytes(), before)
            self.run_cli(path, 'release', 'M1-122', '--by', 'Tanvir/codex')
            self.assertNotIn('edit_files', json.loads(path.read_text())['tasks'][0])

    def test_reservations_reject_patterns_and_existing_directories(self):
        task = self.data['tasks'][0]
        task.update(status='in_progress', owner='Tanvir/codex')
        task['paths'].append('production/')
        for path in ['game/scripts/world/*.gd', 'game/scripts/world/room?.gd', 'game/scripts/world/[a].gd', 'production/plan']:
            with self.subTest(path=path):
                before = copy.deepcopy(self.data)
                self.assertTrue(board.reserve_files(self.data, task['id'], 'Tanvir/codex', [path]))
                self.assertEqual(self.data, before)

    def test_acceptance_closure_requires_its_member_without_reimplementation_claim(self):
        batch = self.data['implementation_batch']
        batch['acceptance_ids'], batch['deferred_ids'] = batch['deferred_ids'], []
        self.data['tasks'][2].update(status='blocked', owner='Asif/codex')
        with tempfile.TemporaryDirectory() as folder:
            path = pathlib.Path(folder) / 'tasks.json'
            path.write_text(json.dumps(self.data), encoding='utf-8')
            for args in [('claim', '--by', 'Asif/codex'), ('done', '--evidence', 'full pass', '--by', 'Tanvir/codex')]:
                before = path.read_bytes()
                with self.assertRaises(SystemExit):
                    self.run_cli(path, args[0], 'M1-75', *args[1:])
                self.assertEqual(path.read_bytes(), before)
            self.run_cli(path, 'done', 'M1-75', '--evidence', 'full pass', '--by', 'Asif/codex')
            self.assertEqual(json.loads(path.read_text())['tasks'][2]['status'], 'done')

    def test_general_picker_cannot_bypass_explicit_batch_claims(self):
        with tempfile.TemporaryDirectory() as folder:
            path = pathlib.Path(folder) / 'tasks.json'
            path.write_text(json.dumps(self.data), encoding='utf-8')
            for command in ['next', 'take']:
                with self.subTest(command=command):
                    before = path.read_bytes()
                    with self.assertRaisesRegex(SystemExit, 'exact task IDs'):
                        self.run_cli(path, command, '--by', 'Tanvir/codex')
                    self.assertEqual(path.read_bytes(), before)


if __name__ == '__main__':
    unittest.main()
