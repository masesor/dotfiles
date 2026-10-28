# Dotfiles setup

Run `./setup` for platform packages and common configuration, or `./setup --scripts-only` for common configuration. `DEV_ENV` defaults to `$HOME/dev`.

Dock setup is optional. Use `./setup --with-dock` to apply the pinned app list in `mac_dock`, or run `./mac_dock` directly to apply only the Dock layout. The saved order is Obsidian, Notion Calendar, Twilight, WhatsApp, Proton Mail, Ghostty, Figma, OpenVPN Connect, ChatGPT, and Spotify.

## AI skills

Common setup automatically runs `env/runs/ai-skills`. It clones the private `masesor/ai-skills` repository into `$DEV_ENV/ai-skills` and runs its installer for Codex and Claude Code. Existing checkouts are reused without fetching. Cursor can discover those clients' skill directories, so separate Cursor links are unnecessary on these machines.

Git and Python 3 must already be available. Authenticate to GitHub with `gh auth login` or configure Git/SSH access before setup. Missing prerequisites or clone access print a skip message and leave the rest of bootstrap running. No login prompt runs inside bootstrap. SSH requires a previously trusted GitHub host key.

Run only this step:

```sh
DEV_ENV="$HOME/dev" ./env/setup ai-skills
```

Preview without network or filesystem changes:

```sh
./env/runs/ai-skills --dry
```

Update the skills explicitly:

```sh
./env/runs/ai-skills --update
```

Updates require a clean checkout on `main` and use a fast-forward merge. Conflicts, local changes during updates, and unrelated destination repositories produce an error without overwriting them. Skill links are checked for every selected client before installation.

Overrides:

- `AI_SKILLS_CLIENTS="codex"` selects clients, separated by spaces. Supported values are `codex`, `claude`, and `cursor`.
- `AI_SKILLS_DIR` changes the checkout location.
- `AI_SKILLS_REPO_URL` changes the Git source, for a fork or test repository.
- `CODEX_HOME` is respected by the skills installer.

The repository owns the skill files, dependencies, and upstream version records. Dotfiles only clone it and invoke its installer. Refresh the client session after changes when needed.
