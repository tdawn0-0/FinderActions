# FinderActions website

The promotional site uses React, TypeScript, Vite and Cloudflare Workers static
assets. Node **24** is the supported project baseline, selected in `.nvmrc` and
`package.json` engines. Use the committed npm lockfile.

From the repository root, with nvm installed:

```bash
cd web
nvm use
npm ci
npm run lint
npm run check:release-links
npm run build
```

These checks need no Cloudflare credentials and do not deploy the site. CI runs
this sequence independently from the macOS Swift checks. `npm run dev` starts the
local development server; `npm run preview` builds and previews locally.

The copyable manifest comes from `src/examples/compress-action.json`; Swift tests
decode this exact fixture. Release links come from `src/release.ts` and deliberately
open the latest release page so versioned DMG filenames cannot become stale.

For authorized deployment, see [the release guide](../docs/releasing.md). Keep
Cloudflare credentials out of source control. Dependency advisory remediation is
separate from these build checks.
