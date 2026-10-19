"""One serial owner runs engine checks only after the campaign queue finishes."""
import time
from run_audit import OUT, suite, export

while not (OUT/'campaigns_complete.json').exists():
    time.sleep(2)
suite()
export()
