{ pkgs, lib, user ? import ./user.nix, ... }:

{
  imports = [
    ./modules/packages.nix
    ./modules/shell.nix
    ./modules/git.nix
  ];

  home = {
    username = lib.mkDefault user.username;
    homeDirectory = lib.mkDefault (if pkgs.stdenv.isDarwin then "/Users/${user.username}" else "/home/${user.username}");
    stateVersion = "24.05";

    # Config files managed directly (replaces GNU Stow)
    file = {
      ".p10k.zsh".source = ./configs/p10k.zsh;
      ".condarc".source = ./configs/condarc;
      ".hushlogin".text = "";
      ".local/bin/ec2" = {
        source = ./scripts/ec2;
        executable = true;
      };
      ".local/bin/obsidian-init" = {
        source = ./scripts/obsidian-init;
        executable = true;
      };
      ".aws/config".source = ./configs/aws-config;
      ".ssh/config".source = ./configs/ssh-config;
    } // lib.optionalAttrs pkgs.stdenv.isDarwin {
      "Library/Application Support/iTerm2/DynamicProfiles/dotfiles.json".source = ./configs/iterm-profile.json;
      ".local/share/raycast/scripts/insert-date.sh" = {
        source = ./scripts/insert-date.sh;
        executable = true;
      };
    };

    # npm global tools — installed/updated on each `home-manager switch`
    activation.npmGlobals = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export PATH="${pkgs.nodejs_22}/bin:$PATH"
      export NPM_CONFIG_PREFIX="$HOME/.npm-global"
      ${pkgs.nodejs_22}/bin/npm install -g \
        @anthropic-ai/claude-code \
        @openai/codex \
        2>/dev/null || true
    '';

    activation.mambaGoto = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      MAMBA_EXE="${pkgs.micromamba}/bin/micromamba"
      MAMBA_ROOT="$HOME/.local/share/mamba"
      if [ ! -d "$MAMBA_ROOT/envs/goto" ]; then
        echo "Creating goto conda env..."
        "$MAMBA_EXE" create -y -n goto -f "${./configs/goto-env.yml}" --root-prefix "$MAMBA_ROOT" 2>/dev/null || true
      fi
    '';

    activation.vscodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      vscode_dir="$HOME/Library/Application Support/Code/User"
      mkdir -p "$vscode_dir"
      for f in settings.json keybindings.json; do
        target="$vscode_dir/$f"
        # Remove stale symlink, then copy as writable
        [ -L "$target" ] && rm "$target"
        cp "${./configs/vscode}/$f" "$target"
        chmod u+w "$target"
      done
    '';

    activation.vscodeExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if command -v code &>/dev/null; then
        while IFS= read -r ext; do
          code --install-extension "$ext" --force 2>/dev/null || true
        done < "${./configs/vscode/extensions.txt}"
      fi
    '';

  };

  xdg.configFile = {
    "btop/btop.conf".source = ./configs/btop.conf;
    # gh/config.yml is managed by programs.gh in modules/git.nix
  } // lib.optionalAttrs pkgs.stdenv.isLinux {
    "Code/User/settings.json".source = ./configs/vscode/settings.json;
    "Code/User/keybindings.json".source = ./configs/vscode/keybindings.json;
    "shpool/config.toml".source = ./configs/shpool.toml;
  };

  # Fonts only on machines with a display
  fonts.fontconfig.enable = pkgs.stdenv.isDarwin;
  home.packages = lib.optionals pkgs.stdenv.isDarwin [
    pkgs.nerd-fonts.hack
    pkgs.nerd-fonts.meslo-lg
  ];

  programs.home-manager.enable = true;
}
