{pkgs, ...}:
pkgs.stdenv.mkDerivation rec {
  pname = "zshnip";
  version = "53d04fcdc1ab938fc8242755378e3647facd6bff";

  src = pkgs.fetchFromGitHub {
    owner = "facetframer";
    repo = "zshnip";
    rev = version;
    sha256 = "4asmcKybGTGK9XAJ4UbpviE31srfjXgoSBFMDkYI9Kc=";
  };

  buildInputs = [pkgs.makeWrapper];

  installPhase = ''
    mkdir -p $out
    cp -r $src/* $out/
  '';

  meta = {
    description = "Zsh snippets plugin";
    license = pkgs.lib.licenses.mit;
  };
}
