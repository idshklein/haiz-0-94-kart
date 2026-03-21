# Local Release Process (Kart + GitHub)

This repository publishes releases from the local machine state.

## Prerequisites

- `kart` installed and authenticated to the remote.
- `gh` (GitHub CLI) installed and authenticated.
- Files exist in repo root:
  - `kart_repo.gpkg`
  - `proj.qgs`

## Required Order

1. Commit your data changes with Kart.
2. Create a new tag locally.
3. Run the local release publisher script.

## Commands

From repository root:

```powershell
kart commit -m "<message>"
kart tag v0.94.X
powershell -ExecutionPolicy Bypass -File .\scripts\publish_release_from_local.ps1 -Tag v0.94.X
```

What the script does:

- Pushes `main` to `origin` (unless `-SkipBranchPush` is used).
- Pushes the selected tag.
- Builds `haiz_release_bundle.zip` from local `kart_repo.gpkg` and `proj.qgs`.
- Generates `SHA256SUMS.txt`.
- Creates or updates the GitHub release and uploads all assets with overwrite.

## Verification

After script completion, verify in GitHub release that assets exist:

- `haiz_release_bundle.zip`
- `kart_repo.gpkg`
- `proj.qgs`
- `SHA256SUMS.txt`
