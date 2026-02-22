{
  description = "GitButler CLI Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
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
  };
}
