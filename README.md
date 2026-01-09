# CTRL-OS Modules

This repository is a collection of curated modules that work great
with [CTRL-OS](https://ctrl-os.com/) (and NixOS).

## Module Documentation

Detailed module documentation and Getting Started guides are soon available on
[docs.ctrl-os.com](https://docs.ctrl-os.com/).

All modules are available via `nixosModules` of this Flake. If you don't use
Flakes, import the module file in `/modules` directly. We will streamline this
later!

Modules follow a simple configuration pattern. Module `foo` has its
configuration under `ctrl-os.foo`. So to enable module `foo`, you
typically write `ctrl-os.foo.enable = true`;


## Available Modules

These are the modules that are currently available. Modules marked
**Testing** or **Beta** are still in development and may change
significantly. Modules marked **Stable** will only change in
backward-compatible ways.

| Module      | Status   | Description                                             |
|-------------|----------|---------------------------------------------------------|
| `developer` | **Beta** | Useful settings for developers using CTRL-OS            |
| `vms`       | **Beta** | Declarative way to run generic VMs in NixOS and CTRL-OS |

## Supported Platforms

There are modules for platform support of certain hardware,
CTRL-OS supports in addition to the platforms supported by upstream NixOS.
platforms marked as **Testing** or **Beta** are still in development and may change significantly.
We also provide installer ISOs for some of the platforms.
To build the ISO run the following command. The installer name is listed in the table below.
If the host platform is not equal to the build platform, cross compilation is used.

```nix
nix build .#packages.<x86_64-linux|aarch64-linux>.<installer name>
```

| Platform                  | Status   | Description                                           | Installer Name            |
|---------------------------|----------|-------------------------------------------------------|---------------------------|
| `nvidia-jetson-orin-nano` | **Beta** | Enables Nvidia Jetson Orin Nano Developer Kit support | `jetsonOrinNanoInstaller` |
