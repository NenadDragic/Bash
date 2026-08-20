# DDNS Update (Old) - DDNS.sh

**⚠️ The hardcoded API key that was here has been rotated out of the script** — it read the key directly from `apikey=<key>` in plaintext. Since that key was already pushed to GitHub, it must still be treated as compromised in the Simply.com control panel (rotate/revoke it there) — removing it from this file does not remove it from git history. The script now reads the key from the `SIMPLY_DDNS_APIKEY` environment variable instead of hardcoding it.

Updates a Dynamic DNS hostname (`car.dragic.com`) via Simply.com's DDNS API.

## How it works

1. Sends a single `curl` GET request to `api.simply.com/ddns.php` with the API key (from `$SIMPLY_DDNS_APIKEY`), domain (`dragic.com`), and hostname (`car`) as query parameters, updating that hostname's DNS record to the caller's current IP.

## Usage

Set `SIMPLY_DDNS_APIKEY` in the environment before running:

```shell
export SIMPLY_DDNS_APIKEY="your-key-here"
./DDNS.sh
```

```shell
#!/bin/bash

# Set SIMPLY_DDNS_APIKEY in the environment before running (do not hardcode it here).
curl -s -L "https://api.simply.com/ddns.php?apikey=${SIMPLY_DDNS_APIKEY}&domain=dragic.com&hostname=car"
```
