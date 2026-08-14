# Cutting a WinMice release

Operator checklist for **Developer ID signed + notarized** releases.

## Prerequisites: Apple signing (once)

### 1. Register the App ID

In [Apple Developer → Identifiers](https://developer.apple.com/account/resources/identifiers/list):

1. Register a macOS App ID.
2. Bundle ID: `cz.anibalribeiro.winmice` (explicit).
3. Description: `WinMice`.

### 2. Create a Developer ID Application certificate

In [Certificates](https://developer.apple.com/account/resources/certificates/list):

1. Create **Developer ID Application**.
2. Follow CSR instructions (Keychain Access → Certificate Assistant).
3. Download the certificate and double-click to install in login keychain.
4. In Keychain Access, select the **private key** under “My Certificates”, then
   **Export…** as a `.p12` with a strong password. Export the identity **with its
   certificate chain** (Developer ID Application + Apple intermediates) — a
   leaf-only `.p12` fails later during `codesign` with opaque chain errors.
5. Keep the password in a password manager.

Base64 for GitHub:

```bash
base64 -i DeveloperIDApplication.p12 | pbcopy
```

If you export the `.p12` yourself (e.g. via `openssl pkcs12`) rather than from
Keychain Access, use `-legacy` on OpenSSL 3: its default AES encryption
produces a `.p12` that `security import` rejects with `MAC verification
failed during PKCS12 import`.

### 3. Create an App Store Connect API key

In [App Store Connect → Users and Access → Integrations → Team Keys](https://appstoreconnect.apple.com/access/integrations/api):

1. Generate a key with **Developer** (or Admin) access.
2. Download the `.p8` once.
3. Record **Key ID**, **Issuer ID**, and your **Team ID** (Membership details on developer.apple.com).

`APPLE_TEAM_ID` is stored as a secret for operator verification and log
context. Notarization itself authenticates with the ASC API key
(`APPLE_API_KEY_ID` / `APPLE_API_ISSUER_ID` / `APPLE_API_KEY_P8`).

### 4. Store secrets on the WinMice repo

Single-line secrets can use interactive `gh secret set`. The `.p8` is a
**multi-line PEM** — pipe the file (do not paste into a one-line prompt):

```bash
base64 -i DeveloperIDApplication.p12 | gh secret set APPLE_DEVELOPER_ID_P12_BASE64 --repo anibalribeiro/WinMice
gh secret set APPLE_DEVELOPER_ID_P12_PASSWORD --repo anibalribeiro/WinMice
# paste password when prompted

gh secret set APPLE_TEAM_ID --repo anibalribeiro/WinMice
gh secret set APPLE_API_KEY_ID --repo anibalribeiro/WinMice
gh secret set APPLE_API_ISSUER_ID --repo anibalribeiro/WinMice

# Multi-line PEM — pipe the file:
gh secret set APPLE_API_KEY_P8 --repo anibalribeiro/WinMice < AuthKey_<KEY_ID>.p8
```

Verify names only:

```bash
gh secret list --repo anibalribeiro/WinMice
```

Required Apple secret names:

- `APPLE_DEVELOPER_ID_P12_BASE64`
- `APPLE_DEVELOPER_ID_P12_PASSWORD`
- `APPLE_TEAM_ID`
- `APPLE_API_KEY_ID`
- `APPLE_API_ISSUER_ID`
- `APPLE_API_KEY_P8`

## Prerequisites: Homebrew tap token

The Release workflow bumps `anibalribeiro/homebrew-winmice` using `HOMEBREW_TAP_TOKEN`.

### 1. Create a fine-grained PAT for the tap

In GitHub → **Settings** → **Developer settings** → **Fine-grained tokens** → **Generate new token**:

| Setting | Value |
| --- | --- |
| Resource owner | `anibalribeiro` |
| Repository access | Only `homebrew-winmice` |
| Permissions | **Contents** → Read and write |

### 2. Store the secret on WinMice

```bash
gh secret set HOMEBREW_TAP_TOKEN --repo anibalribeiro/WinMice
```

```bash
gh secret list --repo anibalribeiro/WinMice | grep HOMEBREW_TAP_TOKEN
```

## Dry-run before the first real tag

After secrets are set, prove the pipeline **without** publishing a GitHub
Release or bumping Homebrew:

1. GitHub → **Actions** → **Release** → **Run workflow**
2. Leave **publish** unchecked (default)
3. Optionally set a dry-run version string
4. Confirm **Notarize app** / **Notarize DMG** / verify steps succeed
5. Download the workflow artifacts and smoke-test Gatekeeper + Accessibility

Only then cut a real `vX.Y.Z` tag.

## Release checklist

1. Ensure Apple + Homebrew secrets above are set, and a dry-run has passed once.

2. Ensure `main` is green locally:

   ```bash
   ./scripts/test-build-signing-mode.sh
   ./scripts/build-app.sh --version 1.0.1 && ./scripts/verify-bundle-metadata.sh dist/WinMice.app 1.0.1
   ```

   When `create-dmg` is installed (`brew install create-dmg`), also verify the disk image:

   ```bash
   ./scripts/package-dmg.sh 1.0.1
   ```

3. Commit/push any pending release notes or docs on `main`.

4. Tag and push:

   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```

5. Watch **Actions** → **Release**:

   ```bash
   gh run watch --repo anibalribeiro/WinMice
   ```

   Confirm steps **Notarize app**, **Verify notarized app**, **Notarize DMG**,
   and **Verify notarized DMG** succeed.

6. Confirm the GitHub Release includes both `WinMice-1.0.1.dmg` and `WinMice-1.0.1.zip`:

   ```bash
   gh release view v1.0.1 --repo anibalribeiro/WinMice
   ```

7. Confirm the tap cask was bumped; test install. The cask's `sha256` is the
   **DMG's** checksum (not the zip's) — that's what the workflow's Checksum
   step computes and what `brew` verifies:

   ```bash
   brew uninstall --cask winmice 2>/dev/null || true
   brew untap anibalribeiro/winmice 2>/dev/null || true
   brew tap anibalribeiro/winmice
   brew trust anibalribeiro/winmice
   brew install --cask winmice
   ```

8. Smoke-test Gatekeeper: open `/Applications/WinMice.app` **without** Open Anyway. Grant **Accessibility** when prompted.

   **Upgrading from ad-hoc (unsigned) releases:** the first Developer ID build
   is a new code identity. Remove every old WinMice row under
   **System Settings → Privacy & Security → Accessibility**, then re-enable
   `/Applications/WinMice.app`. Later notarized updates keep that identity.

## If notarization fails

`notarytool submit --wait` returns exit status 0 even when Apple reports
`Invalid` or `Rejected`. The Release scripts parse the JSON status and fail
the job; on failure they also print `notarytool log` into the workflow log.

If you need the log again from a laptop with the same API key:

```bash
xcrun notarytool log <submission-id> \
  --key AuthKey_<KEY_ID>.p8 --key-id <KEY_ID> --issuer <ISSUER_ID>
```

That prints the specific rejection (e.g. missing hardened runtime, missing
timestamp, disallowed entitlement). Fix the cause, then re-run — see below.

## Re-running after a failure

Every step from **Import Developer ID certificate** onward is safe to
re-run on the same tag after fixing the cause of a failure:

- Use **Re-run jobs** / **Re-run failed jobs** in the Actions UI for the tag
  workflow run (an empty commit will **not** re-trigger a tag-only workflow).
- `gh release upload ... --clobber` (Publish GitHub Release) overwrites the
  existing release assets rather than failing if the tag already has a
  release.
- The Homebrew tap bump (`update-homebrew-cask.sh` + `git commit`/`push`) is
  idempotent: if the cask is already at the target version/sha256, the diff
  is empty and the commit is skipped.
