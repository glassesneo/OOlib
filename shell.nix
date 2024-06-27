let
  pkgs = import <nixpkgs> {};
in pkgs.mkShell {
  packages = [
    pkgs.nim2
    pkgs.emscripten
    pkgs.nimble
  ];
}

