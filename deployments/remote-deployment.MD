## Deployment of the VPS happen via:
1. (Build the VPS with nixos-anywhere)
2. Push the shadowJar
3. Nix runs the jar as a system service

### Necessary to deploy:
`deployments/keys/etc/ssh` -> host-key & host-key.pub (ssh server keys)

### Deployments to machines with just 1GB RAM
I wasn't able to build the system on a 1GB Google instance. If this happens, temporarily scale the instance for the install. Then scale down again.

### Deploy command:
(needs to be run from the **project root**)
```bash
# Build shadowJar
./gradlew shadowJar

# Ensure the JAR is visible to Nix
git add -N -f build/libs/nannuo-bot-1.0-SNAPSHOT-all.jar

# Deploy
nix run github:nix-community/nixos-anywhere -- \
--flake .#gce-x86 \
--extra-files deployments/keys \
passwordless-sudo@[host-ip]
```

If the VPS has enough RAM, one could also add `--build-on remote` to build on the Server.
