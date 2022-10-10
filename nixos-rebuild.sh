#!/bin/sh

set -e

ssh_connection="$1"
configuration_file="$2"

die() { echo "$0: $2" 1>&2; exit "$1"; }

[ -n "$ssh_connection" ] || die 1 "ssh connection argument required"
[ -n "$configuration_file" ] || die 1 "path to configuration.nix argument required"

command -v bw  >/dev/null || die 2 "bitwarden cli required"
command -v esh >/dev/null || die 2 "esh required"

bw unlock --check || die 3 "bitwarden vault is locked"

bw sync

esh "$configuration_file" | ssh "$ssh_connection" "sudo cat > /etc/nixos/configuration.nix"
ssh -t "$ssh_connection" "sudo nixos-rebuild switch"
