#!/bin/sh

set -ex

runtime_dir="$1"

ssh_users_collection=927a8631-da7c-4197-a0ff-8b8bf19c967c
bw list items --collectionid "$ssh_users_collection" \
| jq '[.[].fields[]|select(.name=="sshPublicKey").value]' \
> "$runtime_dir/sshAuthorizedKeys.json"

wg_users_collection=45237f3d-7c00-4a12-893e-5c399432f461
bw list items --collectionid "$wg_users_collection" \
| jq '[.[].fields | {
  publicKey: .[]|select(.name=="wgPublicKey").value,
  allowedIPs: [.[]|select(.name=="wgAllowedIPs").value]
  }]' \
> "$runtime_dir/wgPeers.json"

wg_server_item=e2985bbb-0d6b-4606-8374-a2546436ea27
bw get item "$wg_server_item" \
| jq '{ key: .fields[]|select(.name=="wgPrivateKey").value }' \
> "$runtime_dir/wgPrivateKey.json"
