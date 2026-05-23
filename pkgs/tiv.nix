{ lib, stdenv, fetchFromGitHub, imagemagick }:

stdenv.mkDerivation rec {
  pname = "tiv";
  version = "1.2.1";

  src = fetchFromGitHub {
    owner = "stefanhaustein";
    repo = "TerminalImageViewer";
    rev = "v${version}";
    hash = "sha256-xuJpl/tGWlyo8aKKy0yYzGladLs3ayKcRCodDNyZI9w=";
  };

  buildInputs = [ imagemagick ];

  sourceRoot = "${src.name}/src";

  makeFlags = [ "prefix=${placeholder "out"}" ];

  meta = with lib; {
    description = "Display images in the terminal";
    homepage = "https://github.com/stefanhaustein/TerminalImageViewer";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
