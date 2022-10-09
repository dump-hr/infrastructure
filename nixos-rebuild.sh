#!/bin/sh

set -ex

ssh_connection="$1"
configuration_file="$2"
runtime_dir=./hosts/runtime
ssh_collection_id=927a8631-da7c-4197-a0ff-8b8bf19c967c
wg_collection_id=45237f3d-7c00-4a12-893e-5c399432f461

################################################################################
# generate and copy runtime data

mkdir "$runtime_dir"
trap "rm -r $runtime_dir" EXIT

bw list items --collectionid "$ssh_collection_id" \
| jq '[.[].fields[]|select(.name=="sshPublicKey").value]' \
> "$runtime_dir/sshAuthorizedKeys.json"

bw list items --collectionid "$wg_collection_id" \
| jq '[.[].fields | {
  publicKey: .[]|select(.name=="wgPublicKey").value,
  allowedIPs: [.[]|select(.name=="wgAllowedIPs").value]
  }]' \
> "$runtime_dir/wgPeers.json"

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
