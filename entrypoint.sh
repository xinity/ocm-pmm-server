#!/bin/bash

sed -i "s/1s/${METRICS_RESOLUTION:-1s}/" /opt/prometheus/prometheus.yml
sed -i "s/%(ENV_METRICS_RETENTION)s/${METRICS_RETENTION:-720h}/" /etc/supervisor/supervisord.conf
sed -i "s/%(ENV_METRICS_MEMORY)s/${METRICS_MEMORY:-262144}/" /etc/supervisor/supervisord.conf

sed -i "s/orc_client_user/${ORCHESTRATOR_USER:-orc_client_user}/" /etc/orchestrator.conf.json
sed -i "s/orc_client_password/${ORCHESTRATOR_PASSWORD:-orc_client_password}/" /etc/orchestrator.conf.json

if [ -e /etc/nginx/ssl/server.crt ] && [ -e /etc/nginx/ssl/server.key ]; then
    sed -i 's/#include nginx-ssl.conf/include nginx-ssl.conf/' /etc/nginx/nginx.conf
    if [ -e /etc/nginx/ssl/dhparam.pem ]; then
        sed -i 's/#ssl_dhparam/ssl_dhparam/' /etc/nginx/nginx-ssl.conf
    fi
fi

if [ -n "$SERVER_PASSWORD" ]; then
    echo "${SERVER_USER:-pmm}:$(openssl passwd -apr1 $SERVER_PASSWORD)" > /etc/nginx/.htpasswd
    sed -i 's/auth_basic off/auth_basic "PMM Server"/' /etc/nginx/nginx.conf

    # Disable Grafana HTTP auth
    sed -i '/\[auth.basic\]/ a enabled=false' /etc/grafana/grafana.ini
fi

supervisord -c /etc/supervisor/supervisord.conf
