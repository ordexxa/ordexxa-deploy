#!/bin/sh
set -eu

export PORT="${PORT:-8889}"

sed "s/\${PORT}/${PORT}/g" /etc/otelcol-contrib/config.template.yaml > /tmp/otel-config.yaml

exec /otelcol-contrib --config=/tmp/otel-config.yaml
