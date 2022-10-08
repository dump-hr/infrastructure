#!/bin/sh

set -ex

ssh_connection="$1"
configuration_file="$2"

rsync "$configuration_file" "$ssh_connection:/etc/nixos/configuration.nix" --rsync-path="sudo rsync"
ssh -t "$ssh_connection" "sudo nixos-rebuild switch"

# ssh -t "$ssh_connection" "tmux new -s rebuild 'sudo nixos-rebuild switch || sleep 600'"
