#!/bin/sh
nohup /nginx-vts-exporter -nginx.scrape_uri=http://localhost:8080/status/format/json -telemetry.address 0.0.0.0:8081 -telemetry.endpoint /__/metrics -metrics.namespace=$METRICS_NS &
nginx