{
  stdenv,
  autoPatchelfHook,
  fetchurl,
  lib,
  url,
  zlib,
  dbus,
  version,
  hash ? "",
}:
stdenv.mkDerivation (finalAttrs: {
  inherit version;
  pname = "but";
  src = fetchurl {inherit url hash;};

  dontUnpack = true;
  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    dbus
    zlib
  ];

  installPhase = ''
    mkdir -p $out/bin

    cp $src $out/bin/but
    chmod +x $out/bin/but
  '';

  meta = {
    description = "GitButler CLI - Git, but better";
    license = lib.licenses.fsl11Mit;
    mainProgram = "but";
    platforms = ["x86_64-linux"];
  };
})
