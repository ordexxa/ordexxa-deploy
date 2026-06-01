FROM prom/prometheus:v2.55.1

COPY prometheus.yml /etc/prometheus/prometheus.yml
COPY start.sh /start.sh

USER root
RUN chmod +x /start.sh
USER nobody

EXPOSE 9090

ENTRYPOINT ["/start.sh"]
