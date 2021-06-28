{ nixpkgs ? import <nixpkgs> {} }:
let
  builder = nixpkgs.haskellPackages.callPackage ./builder { };
in
  nixpkgs.stdenv.mkDerivation {
    name = "site";
    preferLocalBuild = true;
    src  = ./content;
    installPhase = ''
      LANG=C.UTF-8 ${builder}/bin/site build
      mkdir -p $out
      cp -a _site/* $out
    '';
  }
