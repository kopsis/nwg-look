{ lib
, stdenv
, fetchFromGitHub
, substituteAll
, buildGoModule
, wrapGAppsHook
, go
, glib
, pkg-config
, cairo
, gtk3
, xcur2png
, libX11
, zlib
}:

let
  fs = lib.fileset;
  sourceFiles =
    fs.difference
      ./.
      (fs.unions [
        (fs.maybeMissing ./result)
        (fs.fileFilter (file: file.hasExt "nix") ./.)
      ]);
in

buildGoModule rec {
  pname = "nwg-look";
  version = "0.2.7";

  src = fs.toSource {
    root = ./.;
    fileset = sourceFiles;
  };

  vendorHash = "sha256-qHWy9OCxENrrWk00YoRveSjqYWIy/fe4Fyc8tc4n34E=";

  # Replace /usr/ directories with the packages output location
  # This means it references the correct path
  #patches = [ ./fix-paths.patch ];

  postPatch = ''
    substituteInPlace tools.go --replace '/usr/local/share' $out/local/share
    substituteInPlace tools.go --replace '/usr/share' $out/share
    substituteInPlace uicomponents.go --replace '"xcur2png"' "\"${xcur2png}/bin/xcur2png\""
  '';

  ldflags = [ "-s" "-w" ];

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook
  ];

  buildInputs = [
    cairo
    xcur2png
    libX11.dev
    zlib
    gtk3
  ];

  propagatedBuildInputs = [
    xcur2png
  ];

  CGO_ENABLED = 1;

  postInstall = ''
    mkdir -p $out/share
    mkdir -p $out/share/nwg-look/langs
    mkdir -p $out/share/applications
    mkdir -p $out/share/pixmaps
    cp stuff/main.glade $out/share/nwg-look/
    cp langs/* $out/share/nwg-look/langs
    cp stuff/nwg-look.desktop $out/share/applications
    cp stuff/nwg-look.svg $out/share/pixmaps
  '';

  meta = with lib; {
    homepage = "https://github.com/nwg-piotr/nwg-look";
    description = "Nwg-look is a GTK3 settings editor, designed to work properly in wlroots-based Wayland environment.";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ max-amb ];
    mainProgram = "nwg-look";
  };
}
