# Developer ID release workflow

FinderActions is distributed outside the Mac App Store as a notarized ZIP. The release pipeline uses Xcode's Developer ID export method instead of manually re-signing bundle contents.

## One-time setup

Requirements:

- An active Apple Developer Program membership
- A `Developer ID Application` certificate and private key in the login Keychain
- An Apple ID app-specific password for the notary service
- Xcode and XcodeGen

Run the setup wizard on each Mac that creates releases:

```bash
./Scripts/setup-signing.sh
```

The wizard validates the signing certificate, stores notarization credentials in macOS Keychain using `notarytool store-credentials`, and writes two non-secret values to the ignored `.release.env` file:

```dotenv
DEVELOPMENT_TEAM=XXXXXXXXXX
NOTARY_PROFILE=FinderActions-notary
```

The Apple ID and app-specific password are never written to the repository or an environment file.

## Versioning

Before releasing, update the values in `Apps/Host/Resources/Info.plist`, `Apps/Settings/Resources/Info.plist`, and `Extensions/FinderSync/Info.plist`:

- `CFBundleShortVersionString`: public semantic version, for example `1.2.0`
- `CFBundleVersion`: monotonically increasing build number, for example `42`

Keep the Host, embedded Settings helper, and FinderSync extension versions aligned.

## Create a release

```bash
./Scripts/release.sh
```

The script fails closed and runs these stages in order:

1. Run all Swift tests.
2. Regenerate the Xcode project from `project.yml`.
3. Create a Release archive with the newest matching `Developer ID Application` certificate for the configured team.
4. Export with Xcode's `developer-id` method and a `Developer ID Application` certificate.
5. Verify nested signatures, secure timestamps, Hardened Runtime flags, and that only Settings links SwiftUI.
6. Submit a temporary ZIP to Apple with `notarytool --wait`.
7. Require an `Accepted` result, staple the ticket to the app, and validate it with `stapler`, `codesign`, and `spctl`.
8. Create the final ZIP and SHA-256 checksum.

Each run creates an immutable timestamped directory:

```text
build/releases/<version>-<build>-<UTC timestamp>/
├── FinderActions.xcarchive
├── export/FinderActions.app
├── FinderActions-<version>-<build>.zip
├── FinderActions-<version>-<build>.zip.sha256
├── FinderActions.entitlements.plist
├── FinderActionsSettings.entitlements.plist
├── FAFinderSync.entitlements.plist
└── notarization.json
```

If Apple rejects the submission, the same directory also contains `notarization-log.json` when a submission ID was issued.

Only distribute the final ZIP produced after stapling. The temporary upload ZIP is deleted automatically.

## Signing model

- The Host intentionally remains outside App Sandbox so it can execute user-authored actions.
- The embedded Settings app is also non-sandboxed so explicit test runs have the same execution behavior as Host.
- Hardened Runtime is enabled for every target.
- Host and Settings receive only the Apple Events entitlement required to automate supported terminal apps.
- The FinderSync extension remains sandboxed and declares no unrelated entitlement.
- No JIT, unsigned executable memory, DYLD, or library-validation exceptions are enabled.

## Common failures

`No Developer ID Application certificate was found`

: Run `./Scripts/setup-signing.sh` and ensure the certificate includes its private key in Keychain Access.

`The notarization Keychain profile is unavailable or invalid`

: Re-run the setup wizard. App-specific passwords can be revoked from the Apple ID account page.

`Notarization status is Invalid`

: Open `notarization-log.json`, fix every reported binary or entitlement issue, increment the build number, and create a new release.

`spctl` rejects an accepted build

: Do not package the pre-notarization upload ZIP. Confirm that `stapler validate` succeeds for `export/FinderActions.app`, then rerun the release from a clean timestamped output directory.
