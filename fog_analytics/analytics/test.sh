#!/bin/bash

curl -X POST -H "Content-Type: application/json"  -d '{"fog_version":"12.34.56","os_name":"Debian","os_version":"10"}' http://fog-analytics-entry.theworkmans.us:/api/records
