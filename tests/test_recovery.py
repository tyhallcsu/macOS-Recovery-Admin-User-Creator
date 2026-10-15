import os
import pathlib
import pty
import select
import subprocess
import tempfile
import time
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]

class RecoveryTests(unittest.TestCase):
    def prompt(self, first, second):
        master, slave = pty.openpty()
        proc = subprocess.Popen(['/bin/bash', '-c', 'source ./create_adminuser.sh; request_password'], cwd=ROOT,
                                stdin=slave, stdout=slave, stderr=slave)
        os.close(slave)
        output = b''
        try:
            for marker, value in [(b'characters): ', first), (b'Confirm password: ', second)]:
                while marker not in output:
                    if not select.select([master], [], [], 3)[0]: self.fail('Password prompt timed out')
                    output += os.read(master, 4096)
                time.sleep(0.05)  # Let Bash enable no-echo input before sending.
                os.write(master, value.encode() + b'\n')
            proc.wait(timeout=3)
            try:
                while select.select([master], [], [], 0.1)[0]:
                    chunk = os.read(master, 4096)
                    if not chunk: break
                    output += chunk
            except OSError:
                pass
            return proc.returncode, output.decode()
        finally:
            if proc.poll() is None: proc.kill(); proc.wait()
            os.close(master)

    def test_password_is_hidden(self):
        code, output = self.prompt('Synthetic-test-987', 'Synthetic-test-987')
        self.assertEqual(code, 0)
        self.assertNotIn('Synthetic-test-987', output)

    def test_bad_passwords_rejected(self):
        for a, b in [('', ''), ('short', 'short'), ('Synthetic-test-987', 'Mismatch-test-987')]:
            self.assertNotEqual(self.prompt(a, b)[0], 0)
        # Read the historical value without duplicating it into a test fixture.
        legacy = subprocess.check_output(['/bin/bash', '-c', 'source ./create_adminuser.sh; printf %s "$LEGACY_PASSWORD"'], cwd=ROOT).decode()
        self.assertNotEqual(self.prompt(legacy, legacy)[0], 0)

    def test_noninteractive_password_refused(self):
        p = subprocess.run(['/bin/bash','-c','source ./create_adminuser.sh; request_password'], cwd=ROOT, input='', capture_output=True, text=True)
        self.assertNotEqual(p.returncode, 0)

    def run_creation(self, mode):
        with tempfile.TemporaryDirectory() as directory:
            volume = pathlib.Path(directory)
            (volume/'var/db/dslocal/nodes/Default').mkdir(parents=True)
            script = '''
source ./create_adminuser.sh
request_password() { PASSWORD='Synthetic-test-987'; }
dscl() {
  case " $* " in
    *" -list "*)
      if [ "$TEST_MODE" = listfail ]; then return 1; fi
      if [ "$TEST_MODE" = existing ]; then echo 'adminuser 501'; else echo 'other 501'; fi ;;
    *" -passwd "*) echo PASSWORD_WRITE; [ "$TEST_MODE" != passfail ] ;;
    *) echo MUTATION ;;
  esac
}
mkdir() { echo MOCK_MKDIR; }
chown() { echo MOCK_CHOWN; }
chmod() { echo MOCK_CHMOD; }
main
'''
            return subprocess.run(['/bin/bash','-c',script], cwd=ROOT, env={**os.environ,'MOUNT_POINT':directory,'TEST_MODE':mode}, capture_output=True, text=True)

    def test_creation_uses_entered_password_without_logging_it(self):
        p = self.run_creation('ok')
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertIn('PASSWORD_WRITE', p.stdout)
        self.assertIn('UID 502', p.stdout)
        self.assertNotIn('Synthetic-test-987', p.stdout + p.stderr)

    def test_existing_account_and_failed_listing_never_mutate(self):
        for mode in ['existing', 'listfail']:
            p = self.run_creation(mode)
            self.assertNotEqual(p.returncode, 0)
            self.assertNotIn('MUTATION', p.stdout)
            self.assertNotIn('PASSWORD_WRITE', p.stdout)

    def test_password_write_failure_does_not_report_success(self):
        p = self.run_creation('passfail')
        self.assertNotEqual(p.returncode, 0)
        self.assertNotIn('Created adminuser.', p.stdout)
        self.assertNotIn('MOCK_MKDIR', p.stdout)

    def test_verifier_avoids_readonly_shell_assignments(self):
        text = (ROOT/'check_adminuser.sh').read_text()
        for name in ['UID', 'HOME', 'SHELL']:
            self.assertNotRegex(text, r'(?m)^' + name + '=')
        self.assertNotIn('Password: Password', text)

if __name__ == '__main__':
    unittest.main()
