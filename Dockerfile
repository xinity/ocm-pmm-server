FROM percona/pmm-server:latest


# ############################# #
# Add several custom dashboards #
# ############################# #

WORKDIR /var/lib/grafana/dashboards

RUN wget https://raw.githubusercontent.com/infinityworksltd/graf-db/master/dashboards/Rancher_Stats.json
RUN wget https://raw.githubusercontent.com/xinity/graf-db/master/dashboards/Container_Stats.json


# ############################## #
# Add specific scrapping options #
# ############################## #

COPY conf/tweak-prom.yml /tmp
RUN cat /tmp/tweak-prom.yml >> /opt/prometheus.yml
