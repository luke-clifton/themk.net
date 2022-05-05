{ mkDerivation, base, hakyll, lib }:
mkDerivation {
  pname = "themk-net";
  version = "0.1.0.1";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [ base hakyll ];
  license = lib.licenses.bsd3;
}
