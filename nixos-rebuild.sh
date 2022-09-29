#!/bin/sh

set -ex

ssh_connection="$1"
configuration_file="$2"

rsync "$configuration_file" "$ssh_connection:/etc/nixos/configuration.nix"
ssh -t "$ssh_connection" "tmux new -s nixos-rebuild -d 'sudo nixos-rebuild switch'"
