{ pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;


    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      share = true;
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "aws"
        "extract"
        "z"
      ];
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "zsh-history-substring-search";
        src = pkgs.zsh-history-substring-search;
        file = "share/zsh-history-substring-search/zsh-history-substring-search.zsh";
      }
      {
        name = "k";
        src = pkgs.fetchFromGitHub {
          owner = "supercrabtree";
          repo = "k";
          rev = "master";
          hash = "sha256-32rJjBzqS2e6w/L78KMNwQRg4E3sqqdAmb87XEhqbRQ=";
        };
      }
    ];

    shellAliases = {
      # eza aliases
      ls = "eza --icons";
      ll = "eza -l --icons";
      la = "eza -la -t accessed --icons";
      lt = "eza --tree --icons";
      tree = "eza --tree --icons --level 2";

      # mamba
      mamba = "micromamba";
      ca = "micromamba activate";
    } // lib.optionalAttrs pkgs.stdenv.isDarwin {
      zcat = "gzcat";
    };

    sessionVariables = {
      # Claude Code (Bedrock)
      # CLAUDE_CODE_USE_BEDROCK = "1";
      AWS_REGION = "us-west-2";
      ANTHROPIC_SMALL_FAST_MODEL = "us.anthropic.claude-3-5-haiku-20241022-v1:0";

      # Autosuggestion style
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=#606a6e";
    } // lib.optionalAttrs pkgs.stdenv.isDarwin {
      CONDA_SUBDIR = "osx-arm64";
    };

    # mkBefore ensures this runs at the top of .zshrc
    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # Source p10k config early so the theme doesn't launch the wizard
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
        typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')
      ''
        # --- Micromamba ---
        export MAMBA_EXE="${pkgs.micromamba}/bin/micromamba"
        export MAMBA_ROOT_PREFIX="$HOME/.local/share/mamba"
        __mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2>/dev/null)"
        if [ $? -eq 0 ]; then
            eval "$__mamba_setup"
        else
            alias micromamba="$MAMBA_EXE"
        fi
        unset __mamba_setup
        unset CONDA_DEFAULT_ENV CONDA_PREFIX CONDA_PROMPT_MODIFIER CONDA_SHLVL 2>/dev/null
        micromamba activate goto

        # --- Claude Code model (set here, not sessionVariables, to survive VSCode server restarts) ---
        export ANTHROPIC_MODEL="us.anthropic.claude-opus-4-6-v1[1m]"

        # --- Sensitive env vars (not in nix store) ---
        [[ -f "$HOME/.env.local" ]] && source "$HOME/.env.local"

        # --- Source uv/cargo env if present ---
        [[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"
        [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

        # --- Custom functions (sourced from scripts/) ---
        source ${../scripts/unfreeze.zsh}
        source ${../scripts/switchaws.zsh}

      ''
    ];
  };

  # Ensure custom bin dirs are in PATH
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.npm-global/bin"
  ];
}
