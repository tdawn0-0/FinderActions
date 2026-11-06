#!/usr/bin/env python3
"""Document validation and a separate fail-closed integration adoption gate."""
import argparse
import copy
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SECTIONS = ['Existing evidence','Architecture candidates','Proposed default','Trust protocol','Lifecycle decisions','Isolated packaging','Matrix','Measurements','Cleanup','Adoption gates','Open decisions']
CASES = {'allowed-finder','wrong-identifier','wrong-server','unsigned-peer','sandbox-denied','settings-role','legacy-notifications','hello-before-paths','lost-reply','reconnect-cache','approval-denied','install','upgrade','uninstall','login','quit','manual-relaunch','crash','duplicate-instance','footprint','cleanup'}
PLATFORMS = {'macos-15','current-supported-macos'}

def check(cases, document, adoption=False):
    assert all('## '+s+'\n' in document for s in SECTIONS), 'missing section'
    ids = [c['id'] for c in cases]
    expected = {p+'-'+c for p in PLATFORMS for c in CASES}
    assert len(set(ids)) == len(ids) and set(ids) == expected, 'missing/duplicate matrix cases'
    pending = []
    for c in cases:
        assert c['platform'] in PLATFORMS
        assert c['status'] in {'NOT_RUN','PASS','FAIL','BLOCKED'}, 'unknown status'
        for field in ['peer_role_signing_class','setup','expected_outcome','cleanup']:
            assert isinstance(c[field], str) and c[field].strip(), 'missing '+field
        assert isinstance(c['evidence_artifact'],list)
        if c['status'] == 'PASS':
            assert c['actual_environment'] and c['evidence_artifact'], 'PASS requires environment and artifact'
            for artifact in c['evidence_artifact']:
                path = Path(artifact)
                assert not path.is_absolute() and '..' not in path.parts, 'artifact must be repository relative'
                assert (ROOT.parent/path).is_file(), 'missing evidence artifact'
        if c['status'] in {'NOT_RUN','BLOCKED','FAIL'}:
            assert c['blocking_reason'].strip(), 'unpassed case needs reason'
            pending.append(c['id'])
    if adoption:
        assert not pending, 'Adoption blocked: '+', '.join(pending)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--require-adoption-ready',action='store_true')
    args = parser.parse_args()
    cases = json.loads((ROOT/'020-ipc-integration-matrix.json').read_text())
    doc = (ROOT/'020-ipc-integration-design.md').read_text()
    check(cases,doc)
    bad = [cases[:-1]]
    for status in ['PASS','UNKNOWN']:
        mutation = copy.deepcopy(cases)
        mutation[0]['status'] = status
        mutation[0]['evidence_artifact'] = []
        bad.append(mutation)
    for mutation in bad:
        try:
            check(mutation,doc)
        except (AssertionError,KeyError):
            pass
        else:
            raise AssertionError('invalid matrix accepted')
    if args.require_adoption_ready:
        check(cases,doc,adoption=True)
    print('PASS: design contract, 42 integration gates, and negative self-checks; integration status not implied')

if __name__ == '__main__':
    try:
        main()
    except (AssertionError,KeyError,ValueError) as error:
        raise SystemExit(str(error))
