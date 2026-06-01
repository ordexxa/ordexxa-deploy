#!/bin/sh
set -eu

export PORT="${PORT:-9090}"

exec /bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus \
  --web.listen-address=0.0.0.0:${PORT} \
  --web.enable-lifecycle
