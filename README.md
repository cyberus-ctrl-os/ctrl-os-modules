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

Module documentation lives on
[docs.ctrl-os.com](https://docs.ctrl-os.com/modules/). Click the
module link to go directly to the documentation of a specific module.

Modules may not be supported on all releases. We use the following
status symbols:

- ✅ - Supported
- 🚧 - Planned/WIP
- ❌ - Not Planned

| Module                                                             | Status   | Unstable | 26.05 | 24.05 | Description                                  |
|--------------------------------------------------------------------|----------|----------|-------|-------|----------------------------------------------|
| [`developer`](https://docs.ctrl-os.com/modules/ctrl-os-developer/) | **Beta** | ✅       | 🚧    | ✅    | Useful settings for developers using CTRL-OS |
| [`vms`](https://docs.ctrl-os.com/modules/ctrl-os-vms/)             | **Beta** | ✅       | 🚧    | ❌    | Declarative way to run generic VMs           |

## Hardware Support

CTRL-OS works fine on many platforms. Especially Intel/AMD systems
should in general Just Work. We maintain opinionated hardware support
for platforms that have sharp edges.

Just like modules, hardware support status depends on the release.

| Platform                | Status      | Unstable | 26.05 | 24.05 |
|-------------------------|-------------|----------|-------|-------|
| Nvidia Jetson Orin Nano | **Planned** | 🚧       | 🚧    | ❌    |
