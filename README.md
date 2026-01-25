# CTRL-OS Modules

This repository is a collection of curated modules that work great
with [CTRL-OS](https://ctrl-os.com/) (and NixOS).

## Module Documentation

Detailed module documentation and Getting Started guides are soon available on
[docs.ctrl-os.com](https://docs.ctrl-os.com/).

All modules are available via `nixosModules` of this Flake. If you don't use
Flakes, import the module file in `/modules` directly. We will streamline this
later!

Modules have different purposes and semantics, and thus interfaces. Read the
usage for your chosen modules for more details about their use.

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
| [`profiles`](https://docs.ctrl-os.com/modules/ctrl-os-profiles/)   | **Beta** | ✅       | 🚧    | ✅    | Different opinionated settings for CTRL-OS   |
| [`vms`](https://docs.ctrl-os.com/modules/ctrl-os-vms/)             | **Beta** | ✅       | 🚧    | ❌    | Declarative way to run generic VMs           |

## Hardware Support

CTRL-OS works fine on many platforms. Especially Intel/AMD systems
should in general Just Work. We maintain opinionated hardware support
for platforms that have sharp edges.

Just like modules, hardware support status depends on the release.

| Platform                | Status      | Unstable | 26.05 | 24.05 |
|-------------------------|-------------|----------|-------|-------|
| Nvidia Jetson Orin Nano | **Planned** | 🚧       | 🚧    | ❌    |
