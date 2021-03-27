{ mkDerivation, base, hakyll, stdenv }:
mkDerivation {
  pname = "themk-net";
  version = "0.1.0.1";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [ base hakyll ];
  license = stdenv.lib.licenses.bsd3;
}
