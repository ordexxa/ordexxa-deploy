FROM grafana/grafana-oss:11.3.0

COPY provisioning /etc/grafana/provisioning
COPY dashboards /var/lib/grafana/dashboards
COPY start.sh /start.sh

USER root
RUN chmod +x /start.sh
USER grafana

EXPOSE 3000

ENTRYPOINT ["/start.sh"]
