# Security

## Reporting a problem

TODO: who should problems go to, and how? Please don't open a public issue for a
vulnerability.

## Secrets

None. The addon has no keys, tokens or network access; the game doesn't allow addons any.
`tools/gen_data.py` downloads public spell data from wago.tools without a login. Never commit
secrets.

## What the addon can access

It runs inside the WoW client with the normal addon permissions. Out of combat it reads the
buffs on your own character, to offer them on the Buffs tab and learn their ranks. It never calls
protected functions; it only creates frames and hands spell IDs to Blizzard's aura containers.
It saves its settings in `LeboofDB`: the profiles (modes, size, positions, the minimap button) and
which profile each character uses, by character name and realm.

## Access

- Repo: `addohm/leboof` on GitHub. This workspace pushes with its own deploy
  key (host alias `deploy-ws-leboof`).
- The Windows install script pulls with the owner's own GitHub login.

TODO: who else can push or release, and how is that granted?
