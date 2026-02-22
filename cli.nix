{
  pkgs ? import <nixpkgs> {},
  lib ? pkgs.lib,
}:
pkgs.stdenv.mkDerivation {
  pname = "gitbutler-cli";
  version = "0.19.3-2869";

  src = pkgs.fetchurl {
    url = "https://releases.gitbutler.com/releases/release/0.19.3-2869/linux/x86_64/but";
    hash = "sha256-uVJF7vlUcJKyvh+cSKuQxHcTpzUV2PQ90tbBFUJFA0M=";
  };

  # This is the magic tool that patches the binary for NixOS
  nativeBuildInputs = [
    pkgs.autoPatchelfHook
  ];

  # Most Rust binaries need these standard libraries dynamically linked
  buildInputs = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    openssl
    dbus
  ];

  # Since we are downloading a raw binary (not a .tar.gz), tell Nix not to unpack it
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin

    # Copy the downloaded source binary to the output bin folder and name it 'but'
    cp $src $out/bin/but
    chmod +x $out/bin/but
  '';

  meta = with lib; {
    description = "GitButler CLI - Git, but better. Modern version control for AI-powered workflows";
    homepage = "https://gitbutler.com";
    downloadPage = "https://gitbutler.com/downloads";
    changelog = "https://github.com/gitbutlerapp/gitbutler/releases";
    # license = licenses.free;
    platforms = platforms.linux;
    mainProgram = "but";
    maintainers = [kmdtaufik];
  };
}
