import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const source = await readFile(new URL('../src/release.ts', import.meta.url), 'utf8');
const match = source.match(/export const latestReleaseURL = ['"]([^'"]+)['"]/);
assert.ok(match, 'Export the shared latestReleaseURL');
const url = new URL(match[1]);
assert.equal(url.href, 'https://github.com/tdawn0-0/FinderActions/releases/latest');
for (const name of ['Hero', 'GettingStarted']) {
  const component = await readFile(new URL(`../src/components/${name}.tsx`, import.meta.url), 'utf8');
  assert.match(component, /import\s+\{\s*latestReleaseURL\s*\}\s+from\s+['"]\.\.\/release['"]/, `${name} imports shared destination`);
  assert.equal((component.match(/href=\{latestReleaseURL\}/g) ?? []).length, 2, `${name} uses shared destination for both release anchors`);
  assert.doesNotMatch(component, /releases\/(?:download|tag)\/v?\d/);
  assert.doesNotMatch(component, /FinderActions-\d[^\s'"<]*\.dmg/);
}
console.log('Release link checks passed');
