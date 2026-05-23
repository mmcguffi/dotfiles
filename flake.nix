{
  description = "Personal dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
  let
    user = import ./user.nix;
  in {
    homeConfigurations = {
      # macOS (Apple Silicon): home-manager switch --flake .
      "${user.username}" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        extraSpecialArgs = { inherit user; };
        modules = [ ./home.nix ];
      };

      # Linux (username matches): home-manager switch --flake .
      "${user.username}@linux" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit user; };
        modules = [ ./home.nix ];
      };

      # EC2 (ec2-user): home-manager switch --flake .#ec2-user
      "ec2-user" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit user; };
        modules = [
          ./home.nix
          { home.username = "ec2-user"; home.homeDirectory = "/home/ec2-user"; }
        ];
      };
    };
  };
}
