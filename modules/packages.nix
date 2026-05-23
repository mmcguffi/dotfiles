{ pkgs, lib, ... }:

let
  tiv = pkgs.callPackage ../pkgs/tiv.nix { };
in
{
  home.packages = with pkgs; [
    # Core CLI tools
    eza           # modern ls
    dust          # modern du
    bat           # modern cat
    fd            # modern find
    ripgrep       # modern grep
    fzf           # fuzzy finder
    jq            # JSON processor
    htop          # process viewer
    btop          # prettier process viewer
    gum           # shell script UX toolkit

    # Development
    nodejs_22     # Node.js LTS (provides npm)
    python3       # needed by ec2 script + general use
    uv            # Python package manager
    micromamba    # conda package manager (cross-platform)

    # Shell plugins (referenced by modules/shell.nix)
    zsh-powerlevel10k
    zsh-history-substring-search

    # Docs / media
    glow          # markdown renderer
    graphviz      # dot/graph tools
    imagemagick   # image manipulation
    tiv           # terminal image viewer

    # AWS
    awscli2

    # System
    coreutils     # GNU coreutils
    curl
    wget
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    shpool        # persistent shell sessions (like tmux but simpler)
  ];
}
