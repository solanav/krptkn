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
    ] ++ optional pkgs.stdenv.isLinux pkgs.inotify-tools;

    shellHook = ''
        echo
        echo Welcome to Krptkn Development Shell
    '';
}
