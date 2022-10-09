#!/bin/sh

set -ex

ssh_connection="$1"
configuration_file="$2"
runtime_dir=./hosts/runtime

################################################################################
# generate and copy runtime data

mkdir "$runtime_dir"
trap "rm -r $runtime_dir" EXIT

./generate-runtime.sh "$runtime_dir" || exit

#ssh "$ssh_connection" <<EOF
#[ -d /etc/nixos/runtime ] && sudo rm -rv /etc/nixos/runtime
#sudo mkdir -v /etc/nixos/runtime
#EOF
#
#grep -o "runtime/.*\.json" "$configuration_file" \
#| sed "s#^runtime#$runtime_dir#" \
#| xargs echo \
#| xargs -I{} rsync {} "$ssh_connection:/etc/nixos/runtime/" --rsync-path="sudo rsync"

ssh "$ssh_connection" "sudo rm -rf /etc/nixos/runtime"

grep -o "runtime/.*\.json" "$configuration_file" \
| sed "s#^runtime#$runtime_dir#" \
| xargs echo \
| xargs -I{} rsync {} "$ssh_connection:/etc/nixos/runtime/" \
    --mkpath --rsync-path="sudo rsync"

################################################################################
# update configuration.nix

rsync "$configuration_file" "$ssh_connection:/etc/nixos/configuration.nix" \
  --rsync-path="sudo rsync"

ssh -t "$ssh_connection" "sudo nixos-rebuild switch"
