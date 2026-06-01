FROM otel/opentelemetry-collector-contrib:0.114.0

COPY config.template.yaml /etc/otelcol-contrib/config.template.yaml
COPY start.sh /start.sh

USER root
RUN chmod +x /start.sh
USER 10001

EXPOSE 8889

ENTRYPOINT ["/start.sh"]
