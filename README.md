# Dotfiles

Personal environment managed with [Nix](https://nixos.org/) + [Home Manager](https://github.com/nix-community/home-manager). Works on macOS and Linux from the same config.

## Install (new machine)

```bash
git clone https://github.com/mmcguffi/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
exec zsh
```

This will:
1. Prompt for your identity (username, name, email) and write `user.nix`
2. Install Nix (if not already present)
3. Enable flakes
4. Run `home-manager switch` which installs all packages and symlinks all configs

Then add your secrets:
```bash
cp ~/dotfiles/configs/env.local.example ~/.env.local
# Fill in TOWER_ACCESS_TOKEN, etc.
```

## Update after config changes

```bash
home-manager switch --flake ~/dotfiles
```

## Structure

```
dotfiles/
├── flake.nix              Entry point — defines targets for macOS/Linux
├── home.nix               Main config — imports modules, manages raw config files
├── user.nix               Profile-neutral identity placeholder; bootstrap rewrites it
├── bootstrap.sh           One-command setup for a fresh machine
├── pkgs/
│   └── tiv.nix            Custom package derivations not in nixpkgs
├── modules/
│   ├── packages.nix       CLI tools (eza, dust, btop, awscli2, micromamba, etc.)
│   ├── shell.nix          Zsh + oh-my-zsh + powerlevel10k + aliases + functions
│   └── git.nix            Git + GitHub CLI
├── configs/
│   ├── p10k.zsh           Powerlevel10k theme
│   ├── btop.conf          Btop system monitor
│   ├── condarc            Conda channels (conda-forge, bioconda)
│   ├── claude-settings.json  Claude Code settings
│   ├── vscode/            VS Code settings, keybindings, and extensions list
│   ├── obsidian/          Obsidian vault settings (app, hotkeys, plugins, etc.)
│   ├── Brewfile           macOS casks and tap-only tools
│   ├── ec2-instances.example.zsh  Template for local EC2 aliases
│   └── env.local.example  Template for secrets (not committed)
└── scripts/
    ├── ec2                Custom EC2 instance manager
    └── obsidian-init      Apply Obsidian settings to a vault
```

## Add a new package

Add it to `modules/packages.nix`:
```nix
home.packages = with pkgs; [
  # ...
  new-tool
];
```

Then `home-manager switch --flake ~/dotfiles`.

## App settings

**VS Code** — settings, keybindings, and extensions are tracked in `configs/vscode/`. On `home-manager switch`, settings are symlinked and extensions are auto-installed (if `code` CLI is available).

**Obsidian** — vault-agnostic settings are tracked in `configs/obsidian/`, and shared vault templates are tracked in `configs/obsidian-vault/`. Apply them to a vault:
```bash
obsidian-init ~/path/to/vault    # defaults to ~/Documents/notes
```

**Raycast** — script commands are placed at `~/.local/share/raycast/scripts/`. After first install, add that directory in Raycast → Extensions → Script Commands → Add Directory. Then add hotkey.

**shpool** (Linux/EC2 only) — persistent shell sessions that survive SSH disconnects. Installed automatically on Linux. SSH config auto-attaches to a shpool session for any `dev-*`, `bigdev-*`, or `nf-*` host. Falls back to a normal shell if shpool isn't available.

## Add a new config file

Add it to `home.file` in `home.nix`:
```nix
home.file.".config/app/config.toml".source = ./configs/app.toml;
```

Or for XDG config paths:
```nix
xdg.configFile."app/config.toml".source = ./configs/app.toml;
```

## Rollback

```bash
home-manager generations    # list previous states
home-manager switch --rollback
```

## Personalization

Edit `user.nix` to set your identity:
```nix
{
  username = "youruser";
  fullName = "Your Name";
  email = "you@example.com";
}
```

This drives the flake target names, git config, and home directory paths. The bootstrap script will prompt for these values if `user.nix` doesn't exist or still has placeholder values. Keep committed `user.nix` profile-neutral before publishing.

For EC2 aliases, copy `configs/ec2-instances.example.zsh` to `~/.config/ec2-instances.zsh` and replace the sample instance IDs. The `ec2` helper also accepts a raw instance ID without any local alias file.

## Platform targets

| Platform | Flake target (auto-detected) |
|----------|------------------------------|
| macOS (Apple Silicon) | `<username>` |
| Linux (x86_64) | `<username>@linux` |

`bootstrap.sh` and `home-manager switch --flake ~/dotfiles` auto-detect the right target.

## What's NOT tracked (intentionally)

- `~/.env.local` — secrets (TOWER_ACCESS_TOKEN, etc.)
- `~/.config/ec2-instances.zsh` — private EC2 instance aliases/IDs
- `~/.config/gh/hosts.yml` — GitHub auth tokens
- `~/.zsh_history` — shell history
- `~/.npm-global/` — npm globals (installed via activation hook)
