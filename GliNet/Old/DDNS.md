# DDNS Update (Old) - DDNS.sh

**⚠️ Contains a live API key committed in plaintext** — the `apikey` query parameter below is a real Simply.com API credential. Since this file is already pushed to GitHub, treat that key as compromised: rotate/revoke it in the Simply.com control panel and update whatever currently uses it, then keep any replacement out of git (env var, secrets file, etc.) rather than hardcoded in the script.

Updates a Dynamic DNS hostname (`car.dragic.com`) via Simply.com's DDNS API.

## How it works

1. Sends a single `curl` GET request to `api.simply.com/ddns.php` with the API key, domain (`dragic.com`), and hostname (`car`) as query parameters, updating that hostname's DNS record to the caller's current IP.

## Usage

```shell
#!/bin/bash
curl -s  -L "https://api.simply.com/ddns.php?apikey=VEoAX8fMFqaxOkmg&domain=dragic.com&hostname=car"

```
