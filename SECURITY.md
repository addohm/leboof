# Security

## Reporting a problem

TODO: who should problems go to, and how? Please don't open a public issue for a
vulnerability.

## Secrets

None. The addon has no keys, tokens or network access; the game doesn't allow addons any.
`tools/gen_data.py` downloads public spell data from wago.tools without a login. Never commit
secrets.

## What the addon can access

It runs inside the WoW client with the normal addon permissions. It never reads aura data or calls
protected functions; it only creates frames and hands spell IDs to Blizzard's aura containers.
It saves its settings (modes, size, position) in `LeboofCharDB`, per character.

## Access

- Repo: `addohm/leboof` on GitHub. This workspace pushes with its own deploy
  key (host alias `deploy-ws-leboof`).
- The Windows install script pulls with the owner's own GitHub login.

TODO: who else can push or release, and how is that granted?
