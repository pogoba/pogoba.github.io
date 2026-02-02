{
  description = "Peter Okelmann's website";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    # Fixed-output derivation to fetch Hugo/Go modules.
    # Update vendorHash after changing go.mod/go.sum:
    #   nix develop -c hugo mod vendor && nix hash path _vendor && rm -rf _vendor
    vendorHash = "sha256-7MuemNfY4NlYmYdHO0KOjxcK01HGewuO3JddI70JFqI=";
    hugoModules = pkgs.stdenvNoCC.mkDerivation {
      name = "hugo-modules";
      src = ./.;
      nativeBuildInputs = with pkgs; [ hugo go cacert git ];
      buildPhase = ''
        export HOME=$TMPDIR
        hugo mod vendor
      '';
      installPhase = ''
        cp -r _vendor $out
      '';
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
      outputHash = vendorHash;
    };
  in {

    packages.${system}.default = pkgs.stdenvNoCC.mkDerivation {
      pname = "website";
      version = self.shortRev or self.dirtyShortRev or "dev";
      src = ./.;
      nativeBuildInputs = with pkgs; [ hugo go ];
      buildPhase = ''
        cp -rT ${hugoModules} _vendor
        hugo --minify
      '';
      installPhase = ''
        cp -r public $out
      '';
    };

    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        go
        hugo
      ];
    };

  };
}
