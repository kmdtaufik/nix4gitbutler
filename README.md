<div align="center">

# nix4gitbutler

<img width="100px" src="https://gitbutler-docs-images-public.s3.us-east-1.amazonaws.com/md-logo.png" alt="GitButler logo" />

**A Nix flake providing pre-compiled binaries for GitButler (GUI & CLI)**

[![NixOS](https://img.shields.io/badge/NixOS-5277C3?logo=nixos&logoColor=white)](https://nixos.org/)
[![GitButler](https://img.shields.io/badge/GitButler-CLI-blue)](https://gitbutler.com)

</div>

---

## About GitButler

**GitButler** is a modern Git-based version control interface built from the ground up for AI-powered workflows. This flake pulls the official upstream `.deb` and CLI binaries and patches them for NixOS, completely bypassing the heavy Rust/Tauri compile times.

### Available Packages

This flake exposes two explicit outputs:

- `gui` (Default): The full Tauri desktop application. This package _also_ includes the `but` CLI wrapper.
- `cli`: The standalone, lightweight Rust binary (`but`) for terminal-only workflows.

🚨 **IMPORTANT: Mutual Exclusivity** 🚨
Do **not** attempt to install both the `gui` and `cli` packages simultaneously. Because both packages provide the `/bin/but` executable, Nix's native environment builder will throw a file collision error and refuse to build your system. Choose one or the other.

---

## Installation

### NixOS Configuration (Flake)

Add the flake to your `flake.nix` inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix4gitbutler.url = "github:kmdtaufik/nix4gitbutler";
  };

  outputs = { nixpkgs, inputs, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [{

        # 🟢 Option A: Install the full Desktop GUI (Default)
        environment.systemPackages = [
          inputs.nix4gitbutler.packages.x86_64-linux.default
        ];

        # 🔵 Option B: Install ONLY the Terminal interface (CLI)
        # environment.systemPackages = [
        #   inputs.nix4gitbutler.packages.x86_64-linux.cli
        # ];

      }];
    };
  };
}
```

### Home Manager

```nix
{
  inputs = {
    nix4gitbutler.url = "github:kmdtaufik/nix4gitbutler";
  };

  outputs = { inputs, ... }: {
    home.packages = [
      inputs.nix4gitbutler.packages.x86_64-linux.default # Choose GUI...
      # inputs.nix4gitbutler.packages.x86_64-linux.cli   # ...Or CLI
    ];
  };
}
```

### Try without installing

You can run either application instantly without modifying your system configuration:

```bash
# Run the Desktop GUI
nix run github:kmdtaufik/nix4gitbutler

# Run the pure CLI
nix run github:kmdtaufik/nix4gitbutler#cli
```
