FROM otel/opentelemetry-collector-contrib:0.114.0

COPY config.yaml /etc/otelcol-contrib/config.yaml

EXPOSE 8889

ENTRYPOINT ["/otelcol-contrib"]
CMD ["--config=/etc/otelcol-contrib/config.yaml"]
