"""Record prior evidence as historical evidence, never as a current rerun."""
import hashlib
import subprocess
from run_audit import ROOT, OUT, write

paths=[
    '_mockup/release_audit_v130b/RELEASE_AUDIT.md',
    '_mockup/release_audit_v130b/residual_review.md',
    '_mockup/release_audit_v130b/log_summary.json',
    '_mockup/release_audit_v130b/performance_summary.json',
    '_mockup/release_audit_v130b/provenance.json',
    'docs/handoff/V130R_FIX_RELEASE_BLOCKERS_2026-10-19.md',
    'docs/handoff/V130R_FIX_DIALOGUE_OVERFLOW_2026-10-19.md',
    'docs/handoff/V130R_REBALANCE_2026-10-18.md',
    'docs/handoff/V130R_FIX_COMMANDS_2026-10-18.md',
    'tmp/v130r_b04/v13_report/day_curve.md',
    'tmp/v130r_b04/v13_report/stacking_compare.md',
    'tmp/v130r_b04/v13_report/final_integrity.json',
]
rows=[dict(path=p,exists=(ROOT/p).is_file(),sha256=hashlib.sha256((ROOT/p).read_bytes()).hexdigest() if (ROOT/p).is_file() else None) for p in paths]
wave=(ROOT/'data/waves.json').read_bytes().replace(b'\r\n',b'\n')
historic=subprocess.check_output(['git','show','0dec2aacda020cd0c76a3c5358a3ecb760ed5294:data/waves.json'],cwd=ROOT).replace(b'\r\n',b'\n')
write(OUT/'reused_evidence.json',dict(current_head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),prior_audit_product_sha='e40eb91c4902e72237783508105004be7e4d989e',balance_10runs_product_sha='0dec2aacda020cd0c76a3c5358a3ecb760ed5294',waves_identical_to_balance_baseline_after_lf_normalization=wave==historic,files=rows,read_only_sidecar_agent='01a151ef-5b87-7e61-981b-633103aea766',not_a_full_review_agent=True))
print('Historical evidence indexed; waves baseline identical='+str(wave==historic))
