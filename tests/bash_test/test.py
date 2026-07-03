import subprocess
import os

script = os.path.join(os.path.dirname(__file__), "test.sh")
result = subprocess.run(["bash", script], capture_output=True, text=True)

print(result.stdout, end="")

if result.returncode != 0:
    print(result.stderr, end="")
