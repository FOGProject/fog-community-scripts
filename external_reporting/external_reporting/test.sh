#!/bin/bash

curl -X POST -H "Content-Type: application/json"  -d '{"fog_version":"testing","os_name":"testing","os_version":"testing"}' https://stats-api.fogproject.org/api/records
