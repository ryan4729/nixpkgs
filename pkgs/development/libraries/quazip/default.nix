{ fetchFromGitHub, stdenv, zlib, qtbase, qmake, fixDarwinDylibNames }:

stdenv.mkDerivation rec {
  pname = "quazip";
  version = "0.7.6";

  src = fetchFromGitHub {
    owner = "stachenov";
    repo = pname;
    rev = version;
    sha256 = "1p6khy8fn9bwp14l6wd3sniwwm5v216l8xncfb7a6psjzvq5ypy6";
  };
  patches = [ ./darwin.patch ];

  buildInputs = [ zlib qtbase ];
  nativeBuildInputs = [ qmake ]
    ++ stdenv.lib.optional stdenv.isDarwin fixDarwinDylibNames;

  meta = with stdenv.lib; {
    description = "Provides access to ZIP archives from Qt programs";
    license = licenses.gpl2Plus;
    homepage = https://stachenov.github.io/quazip/; # Migrated from http://quazip.sourceforge.net/
    platforms = with platforms; linux ++ darwin;
  };
}
