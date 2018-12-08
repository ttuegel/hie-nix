{ pkgs ? (import (import ./fetch-nixpkgs.nix) {}) }:

let
  hie82Pkgs = import ./ghc-8.2.nix { inherit pkgs; };
  hie84Pkgs = (import ./ghc-8.4.nix { inherit pkgs; }).override {
    overrides = self: super: {
      # https://github.com/input-output-hk/stack2nix/issues/103
      ghc-syb-utils = null;
      # GHC 8.4 core libs
      mtl = null;
      parsec = null;
      stm = null;
      text = null;
      Cabal = null;
    };
  };
  jse = pkgs.haskell.lib.justStaticExecutables;
  enableProfiling = drv:
    let inherit (pkgs.haskell) lib; in
    lib.overrideCabal drv (drv: {
      enableExecutableProfiling = true;
      enableLibraryProfiling = true;
      configureFlags =
        [
          ''--ghc-options=-with-rtsopts=-p''
          ''--ghc-options=-with-rtsopts=-h''
        ]
        ++ (drv.configureFlags or []);
    });
in with pkgs; rec {
 stack2nix = pkgs.stack2nix;
 hies = runCommandNoCC "hies" {
   buildInputs = [ makeWrapper ];
 } ''
   mkdir -p $out/bin
   ln -s ${hie82}/bin/hie $out/bin/hie-8.2
   ln -s ${hie84}/bin/hie $out/bin/hie-8.4
   makeWrapper ${hie84}/bin/hie-wrapper $out/bin/hie-wrapper \
     --prefix PATH : $out/bin
 '';
 hie82 = enableProfiling hie82Pkgs.haskell-ide-engine;
 hie84 = enableProfiling hie84Pkgs.haskell-ide-engine;
}
