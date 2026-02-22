<div align="center">

# nix4gitbutler-cli

<img width="100px" src="https://gitbutler-docs-images-public.s3.us-east-1.amazonaws.com/md-logo.png" alt="GitButler logo" />

**A Nix flake for the GitButler CLI (`but`)**

[![NixOS](https://img.shields.io/badge/NixOS-5277C3?logo=nixos&logoColor=white)](https://nixos.org/)
[![GitButler](https://img.shields.io/badge/GitButler-CLI-blue)](https://gitbutler.com)

</div>

---

## About GitButler

<img width="100%" src="https://gitbutler-docs-images-public.s3.us-east-1.amazonaws.com/cli-preview.png" alt="GitButler CLI preview" />

**GitButler** is a modern Git-based version control interface with both a GUI and CLI built from the ground up for AI-powered workflows.

### Key Features

- 🌿 **Stacked Branches** - Create branches stacked on others with automatic restacking
- 🔀 **Parallel Branches** - Work on multiple branches simultaneously
- ✏️ **Easy Commit Management** - Uncommit, reword, amend, move, split and squash commits easily
- ⏪ **Undo Timeline** - Logs all operations for easy undo/revert
- ⚔️ **First Class Conflicts** - Rebases always succeed; conflicts can be resolved in any order
- 🔗 **Forge Integration** - GitHub/GitLab integration for PRs, CI statuses, etc.
- 🤖 **AI Tooling** - Built-in AI for commit messages, branch names, PR descriptions

<img width="100%" src="https://gitbutler-docs-images-public.s3.us-east-1.amazonaws.com/app-preview-light.png" alt="GitButler desktop app preview" />

---

## Installation

### NixOS Configuration (flake)

Add to your `flake.nix` inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix4gitbutler.url = "github:kmdtaufik/nix4gitbutler-cli";
  };

  outputs = { nixpkgs, nix4gitbutler, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [{
        environment.systemPackages = [
          nix4gitbutler.packages.x86_64-linux.cli
        ];
      }];
    };
  };
}
```

Or use the overlay:

```nix
{
  nixpkgs.overlays = [ nix4gitbutler.overlays.default ];
  environment.systemPackages = [ pkgs.gitbutler-cli ];
}
```

### Home Manager

```nix
{
  home.packages = [
    inputs.nix4gitbutler.packages.x86_64-linux.cli
  ];
}
```

### Try without installing

```bash
nix run github:kmdtaufik/nix4gitbutler-cli
```

---

## Project Structure

```
.
├── flake.nix    # Nix flake definition
├── cli.nix      # Package derivation for GitButler CLI
├── update.sh    # Auto-update script
└── README.md    # This file
```

---

## Links

- [GitButler Website](https://gitbutler.com)
- [GitButler Documentation](https://docs.gitbutler.com)
- [GitButler GitHub](https://github.com/gitbutlerapp/gitbutler)
- [GitButler Discord](https://discord.gg/MmFkmaJ42D)

---

## License

This Nix flake is MIT licensed. GitButler itself is under a [Fair Source](https://fair.io/) license.
