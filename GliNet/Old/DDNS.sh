#!/bin/bash

# Set SIMPLY_DDNS_APIKEY in the environment before running (do not hardcode it here).
curl -s -L "https://api.simply.com/ddns.php?apikey=${SIMPLY_DDNS_APIKEY}&domain=dragic.com&hostname=car"

