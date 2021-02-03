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

        # For scripts
        pkgs.python38

        # PSQL for local instance
        pkgs.postgresql
    ] ++ optional pkgs.stdenv.isLinux pkgs.inotify-tools;

    shellHook = ''
        initdb -D .tmp/mydb
        pg_ctl -D .tmp/mydb -l logfile -o "--unix_socket_directories='$PWD'" start

        echo ====================================================================
        echo == Welcome to Krptkn Development Shell
        echo == You can stop the PSQL instance with:
        echo == $ pg_ctl -D .tmp/mydb stop
        echo ====================================================================
    '';
}
