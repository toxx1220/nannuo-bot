Deployment of the VPS happen via:
1. (Build the VPS with nixos-anywhere)
2. Push the shadowJar
3. Nix runs the jar as a system service

Necessary to deploy:
`deployments/keys/etc/ssh` -> host-key & host-key.pub (ssh server keys)

Deploy command:
```bash
nix run github:nix-community/nixos-anywhere --
--flake .#gce-x86
--extra-files keys
root@[host-ip]
```

If the VPS has enough RAM, one could also add `--build-on remote` to build on the Server.
