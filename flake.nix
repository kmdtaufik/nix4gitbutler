{
  description = "GitButler CLI Flake - Git, but better";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system} = {
      cli = pkgs.callPackage ./cli.nix {};
      default = self.packages.${system}.cli;
    };

    devShells.${system}.default = pkgs.mkShell {
      name = "gitbutler-cli-dev";
      packages = [
        self.packages.${system}.cli
        pkgs.git
        pkgs.curl
        pkgs.jq
      ];
      shellHook = ''
        echo "🚀 GitButler CLI development shell"
        echo "   but --version: $(but --version 2>/dev/null || echo 'not built yet')"
        echo ""
        echo "Available commands:"
        echo "  nix build .#     - Build the CLI"
        echo "  ./update.sh      - Update to latest version"
        echo "  ./update.sh -n   - Dry-run update check"
      '';
    };

    # Overlay for easy integration into other flakes
    overlays.default = final: prev: {
      gitbutler-cli = self.packages.${final.system}.cli;
    };
  };
}
