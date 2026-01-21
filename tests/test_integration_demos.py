import subprocess
import pytest
from pathlib import Path
import sys
import os

# Add root directory to path so we can import demos
ROOT_DIR = Path(__file__).parent.parent.absolute()
sys.path.append(str(ROOT_DIR))

# Import Python demos
import demo_01_singlerecon_LCD as demo01
import demo_02_tworecon_LCD as demo02
import demo_03_tworecon_dosecurve_LCD as demo03

@pytest.mark.python_demos
class TestPythonDemos:
    def test_demo_01(self):
        """Run demo_01_singlerecon_LCD.py"""
        # Change CWD to root for proper file access
        os.chdir(ROOT_DIR)
        try:
            demo01.main()
        except Exception as e:
            pytest.fail(f"Demo 01 failed with error: {e}")

    def test_demo_02(self):
        """Run demo_02_tworecon_LCD.py"""
        os.chdir(ROOT_DIR)
        try:
            demo02.main()
        except Exception as e:
            pytest.fail(f"Demo 02 failed with error: {e}")

    def test_demo_03(self):
        """Run demo_03_tworecon_dosecurve_LCD.py"""
        os.chdir(ROOT_DIR)
        try:
            demo03.main()
        except Exception as e:
            pytest.fail(f"Demo 03 failed with error: {e}")

@pytest.mark.octave_demos
class TestOctaveDemos:
    def _run_octave_demo(self, demo_name):
        """Helper to run octave command"""
        cmd = [
            "octave",
            "--no-gui",
            # Add path to Octave's libraries if needed, similar to our manual fix
            # Assuming octave is in path, but we might need to be explicit about pkg load
            # The scripts themselves now should have correct pkg load calls
            "--eval",
            f"addpath(genpath('{ROOT_DIR}/src')); pkg list; {demo_name}"
        ]
        
        # We need to run from ROOT_DIR
        result = subprocess.run(
            cmd,
            cwd=ROOT_DIR,
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            print(f"\n--- OCTAVE STDOUT ---\n{result.stdout}")
            print(f"\n--- OCTAVE STDERR ---\n{result.stderr}")
            pytest.fail(f"Octave demo {demo_name} failed with return code {result.returncode}")

    def test_octave_demo_01(self):
        self._run_octave_demo("demo_01_singlerecon_LCD")

    def test_octave_demo_02(self):
        self._run_octave_demo("demo_02_tworecon_LCD")

    def test_octave_demo_03(self):
        self._run_octave_demo("demo_03_tworecon_dosecurve_LCD")
