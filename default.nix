{ nixpkgs ? import <nixpkgs> {} }:
nixpkgs.haskellPackages.callPackage ./themk.net.nix { }
