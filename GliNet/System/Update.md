# OPKG Update - Update.sh

This script refreshes the OpenWrt/GL.iNet router's `opkg` package index.

## How it works

1. Runs `opkg update` to refresh the list of available packages from the configured feeds.

## Usage

Run this before installing or upgrading packages on the router.

```shell
#!/bin/bash

opkg update
```
