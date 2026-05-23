{ pkgs, user ? import ../user.nix, ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = user.fullName;
        email = user.email;
      };
      pull.rebase = true;
      credential = {
        "https://github.com" = {
          helper = [
            ""
            "!${pkgs.gh}/bin/gh auth git-credential"
          ];
        };
        "https://gist.github.com" = {
          helper = [
            ""
            "!${pkgs.gh}/bin/gh auth git-credential"
          ];
        };
      };
    };

    ignores = [
      ".claude/settings.json"
      ".claude/settings.local.json"
    ];
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "https";
      prompt = "enabled";
      prefer_editor_prompt = "disabled";
      spinner = "enabled";
      aliases = {
        co = "pr checkout";
      };
    };
  };
}
