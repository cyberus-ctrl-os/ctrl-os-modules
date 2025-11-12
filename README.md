# CTRL-OS Modules

This repository is a collection of curated modules that work great
with [CTRL-OS](https://ctrl-os.com/) (and NixOS).

## Module Documentation

Modules follow a simple configuration pattern. Module `foo` has its
configuration under `ctrl-os.foo`. So to enable module `foo`, you
typically write `ctrl-os.foo.enable = true`;

Detailed module documentation is available on
[docs.ctrl-os.com](https://docs.ctrl-os.com/).

## Available Modules

These are the modules that are currently available. Modules marked
**Testing** or **Beta** are still in development and may change
significantly. Modules marked **Stable** will only change in
backward-compatible ways.

| Module      | Status   | Description                                  |
|-------------|----------|----------------------------------------------|
| `developer` | **Beta** | Useful settings for developers using CTRL-OS |
