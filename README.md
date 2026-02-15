# Nannuo Bot

Discord bot built with Kotlin + Kord, packaged with Nix, and deployed to NixOS.

## Quick Start

### 1) Enter the dev environment

If you use direnv:

```bash
direnv allow
```

Or directly with Nix:

```bash
nix develop
```

### 2) Set your Discord token

```bash
export DISCORD_TOKEN=your_token_here
```

### 3) Run the bot

```bash
gradle run
```

Or build and run the fat jar:

```bash
gradle shadowJar
java -jar build/libs/nannuo-bot-*-all.jar
```

## IDE Setup

The devShell automatically syncs the nix jdk folder to .jdk to be used by IDE/Gradle/...

## Nix Build

Build default package for current system:

```bash
nix build
```

Build specific system:

```bash
nix build .#packages.x86_64-linux.default
```

> **Note:** `nix build` fetches a pre-built JAR from GitHub Releases. It does not compile from source.
> To compile locally, use `gradle shadowJar` in the dev shell.

## Release Workflow

The release process is automated via GitHub Actions to ensure Nix package availability and valid JAR URLs.

### Procedure

1.  **Push Changes:** Push code to `main` as usual.
2.  **Tag Release:** Create and push a semantic version tag (e.g., `v1.0.0`).

```bash
git tag v1.0.0
git push origin v1.0.0
```

**Note:** Do not create releases via the GitHub GUI. The automation handles artifact creation and hashing.

### Automated Pipeline

The tag push triggers a multi-stage workflow:

1.  **Stage 1: Pre-release & Artifact Creation**
    - GitHub Actions (GHA) builds the fat JAR from the tag.
    - Creates a **Pre-release** on GitHub containing the JAR.

2.  **Stage 2: Nix Source Update**
    - GHA computes the JAR's SRI hash.
    - Updates `jar-source.nix` with the new URL and hash.
    - Commits and pushes these changes to `main`.

3.  **Stage 3: Verification (Garnix)**
    - The push to `main` triggers Garnix CI.
    - Garnix builds the Nix package using the valid Pre-release JAR.
    - GHA waits for this build to pass.

4.  **Stage 4: Promotion & Deployment**
    - Upon Garnix success, GHA promotes the GitHub Release from **Pre-release** to **Latest/Final**.
    - GHA triggers the `nix-vps` repository to deploy the updated flake.

### Manual Recovery

If you need to update `jar-source.nix` without waiting for GHA (e.g. re-tagging a release):

```bash
nix run .#update-jar -- v1.0.0
```

This downloads the JAR from the given release tag, computes the hash, and writes `jar-source.nix`.

## CI / Garnix

`garnix.yaml` builds selected systems (packages) to ensure the Nix build works and is cached.

## Project Layout

- `src/` — bot source code
- `scripts/` — utility scripts (`update-jar.sh`)
- `jar-source.nix` — URL + hash of the current release JAR (auto-updated by GHA)
- `.github/workflows/` — GitHub Actions release workflow
- `flake.nix` — build/dev/deploy definitions

## Notes

- `Message Content Intent` must be enabled in the Discord Developer Portal.
