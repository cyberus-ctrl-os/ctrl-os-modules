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
