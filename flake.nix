{
  description = "GitButler CLI Flake - Git, but better";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      # Define the systems your flake supports
      systems = ["x86_64-linux"];

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: let
        sources = builtins.fromJSON (builtins.readFile ./sources.json);

        # Extract the data specifically for the system currently being built
        arch = sources.${system} or (throw "Unsupported system: ${system}");
      in {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        packages = {
          cli = pkgs.callPackage ./cli.nix {
            inherit (sources) version;
            url = arch.url.cli;
            hash = arch.hash.cli;
          };
          gui = pkgs.callPackage ./gui.nix {
            inherit (sources) version;
            url = arch.url.gui;
            hash = arch.hash.gui;
          };
          default = config.packages.gui;
        };

        devShells.default = pkgs.mkShell {
          name = "gitbutler-dev";
          packages = [
            pkgs.git
            pkgs.curl
            pkgs.jq
          ];
        };
      };
    };
}
