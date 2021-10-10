# Pi Dev

A Packer script to build a Pi development environment.

Run with powershell:

```powershell
./build-pidev-img.ps1
```

pidev.img can then be written to an SD card.

## Environment

The Packer script installs a Rasbian Lite image with git, Python, NodeJS, and other useful utilities.

SSH and WiFi secrets are taken from a local Vault server. Adjust as appropriate.
