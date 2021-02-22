{ pkgs ? import <nixpkgs> {} }:

let
    # Get optional for linux-only deps
    inherit (pkgs.lib) optional;
in

pkgs.mkShell {
    buildInputs = [
        # Main stuff
        pkgs.erlang
        pkgs.elixir
        pkgs.nodejs

        # Building extractor
        pkgs.libextractor
        pkgs.git
        pkgs.gcc
        pkgs.cmake

        # For scripts
        pkgs.python38

        # PSQL for local instance
        pkgs.postgresql
    ] ++ optional pkgs.stdenv.isLinux pkgs.inotify-tools;

    shellHook = ''
        export LOCALE_ARCHIVE=${pkgs.glibcLocales}/lib/locale/locale-archive
        export LANG=en_US.UTF-8
        export EXTRACTOR_PATH=${pkgs.libextractor.outPath}/lib
        export LD_LIBRARY_PATH=$EXTRACTOR_PATH

        #initdb -D .tmp/mydb --username=krptkn-dev --pwfile=$PWD/config/pgpass
        #pg_ctl -D .tmp/mydb -l logfile -o "--unix_socket_directories='$PWD'" start
        #createdb krptkn_dev -h $PWD -U krptkn-dev

        echo ========================================
        echo == Welcome to Krptkn Development Shell
        echo == You can stop the PSQL instance with:
        echo == $ pg_ctl -D .tmp/mydb stop
        echo ========================================
    '';
}
