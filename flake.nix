{
  description = "Nix flake for claude-plugins and skills-installer CLI tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    claude-plugins-src = {
      url = "github:Kamalnrf/claude-plugins";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      claude-plugins-src,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          claude-plugins = pkgs.callPackage ./packages/claude-plugins.nix {
            src = claude-plugins-src;
          };

          skills-installer = pkgs.callPackage ./packages/skills-installer.nix {
            src = claude-plugins-src;
          };

          default = pkgs.callPackage ./packages/default.nix {
            inherit (self.packages.${system}) claude-plugins skills-installer;
          };
        }
      );

      homeManagerModules = {
        default = import ./modules/home-manager.nix;
        claude-plugins = import ./modules/home-manager.nix;
      };

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              bun
              nodejs
              nixpkgs-fmt
              statix
            ];
          };
        }
      );
    };
}
