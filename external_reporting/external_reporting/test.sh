#!/bin/bash

curl -X POST -H "Content-Type: application/json"  -d '{"fog_version":"testing","os_name":"testing","os_version":"testing"}' https://fog-external-reporting-entries.theworkmans.us:/api/records
