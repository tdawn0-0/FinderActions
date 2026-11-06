#!/usr/bin/env python3
"""Check the design contract, not the production feature."""
import copy
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REQUIRED = {'home-preset','one-file','one-folder','multi-select','explicit-container','empty-with-container','special-paths','missing-path','action-changed-during-run','close-during-run'}
SECTIONS = ['Problem','Current behavior','Proposed controls','Execution semantics','Failure states','Accessibility/localization','Alternatives','Implementation boundaries','Open decisions','Recommendation']

def check(cases, document):
    assert all('## '+heading+'\n' in document for heading in SECTIONS), 'missing section'
    ids = [case['id'] for case in cases]
    assert len(ids) == len(set(ids)) and set(ids) == REQUIRED, 'missing/duplicate case'
    for case in cases:
        inputs = case['inputs']
        preview = case['expected_preview']
        resolved = inputs['paths'] or ([inputs['container']] if inputs['container'] else [])
        assert preview['paths'] == resolved
        assert preview['argv'] == [inputs['interpreter'], inputs['script']] + resolved
        assert preview['FA_PATH_COUNT'] == str(len(resolved))
        assert preview['FA_CWD'] == inputs['container']
        assert case['allowed_controls'] and case['execution_side_effects']
        assert isinstance(inputs['valid'], bool) and inputs['state'] in {'ready','invalid','running'}
        if inputs['state'] == 'running' or not inputs['valid']:
            assert 'Run' not in case['allowed_controls']


def main():
    cases = json.loads((ROOT/'019-live-test-scenarios.json').read_text())
    doc = (ROOT/'019-live-test-design.md').read_text()
    check(cases, doc)
    malformed = [cases[:-1], cases+[cases[0]]]
    wrong = copy.deepcopy(cases)
    wrong[0]['expected_preview']['argv'] = []
    malformed.append(wrong)
    for bad in malformed:
        try:
            check(bad, doc)
        except (AssertionError, KeyError):
            pass
        else:
            raise AssertionError('malformed contract accepted')
    print('PASS: 10 design scenarios and negative contract self-checks')

if __name__ == '__main__':
    main()
