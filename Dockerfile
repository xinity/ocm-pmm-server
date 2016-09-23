FROM ubuntu:latest

EXPOSE 80 443

WORKDIR /opt

# ############### #
# System packages #
# ############### #
RUN apt-get -y update && \
	apt-get install -y apt-transport-https curl git unzip nginx mysql-server python python-requests supervisor && \
	rm -f /etc/cron.daily/apt && \
	useradd -s /bin/false pmm

# ########## #
# Prometheus #
# ########## #
RUN curl -s -LO https://github.com/prometheus/prometheus/releases/download/v1.1.3/prometheus-1.1.3.linux-amd64.tar.gz && \
	mkdir -p prometheus/data && \
	chown -R pmm:pmm /opt/prometheus/data && \
	tar xfz prometheus-1.1.3.linux-amd64.tar.gz --strip-components=1 -C prometheus
COPY prometheus.yml /opt/prometheus/

# ###################### #
# Grafana and dashboards #
# ###################### #
COPY import-dashboards.py grafana-postinstall.sh VERSION /opt/
RUN echo "deb https://packagecloud.io/grafana/stable/debian/ wheezy main" > /etc/apt/sources.list.d/grafana.list && \
	curl -s https://packagecloud.io/gpg.key | apt-key add - && \
	apt-get -y update && \
	apt-get -y install grafana && \
	git clone https://github.com/percona/grafana-dashboards.git && \
	git clone -b alias2instance https://github.com/roman-vynar/grafana_mongodb_dashboards.git && \
	/opt/grafana-postinstall.sh

# ###### #
# Consul #
# ###### #
RUN curl -s -LO https://releases.hashicorp.com/consul/0.7.0/consul_0.7.0_linux_amd64.zip && \
	unzip consul_0.7.0_linux_amd64.zip && \
	mkdir -p /opt/consul-data && \
	chown -R pmm:pmm /opt/consul-data

# ##### #
# Nginx #
# ##### #
COPY nginx.conf nginx-ssl.conf /etc/nginx/
RUN touch /etc/nginx/.htpasswd

# ############ #
# Orchestrator #
# ############ #
COPY orchestrator.conf.json /etc/
RUN curl -s -LO https://github.com/outbrain/orchestrator/releases/download/v1.5.6/orchestrator_1.5.6_amd64.deb && \
	dpkg -i orchestrator_1.5.6_amd64.deb && \
	curl -s -LO https://www.percona.com/downloads/TESTING/pmm/orchestrator-1.5.6-patch.tgz && \
	tar zxf orchestrator-1.5.6-patch.tgz -C /usr/local/orchestrator/ 

# ########################### #
# Supervisor and landing page # 
# ########################### #
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY entrypoint.sh /opt
COPY landing-page/ /opt/landing-page/

# ####################### #
# Percona Query Analytics #
# ####################### #
COPY pt-archiver /usr/bin/
COPY purge-qan-data /etc/cron.daily
COPY qan-install.sh /opt
ADD https://www.percona.com/downloads/TESTING/pmm/percona-qan-api-1.0.5-20160926.920a49c-x86_64.tar.gz \
    https://www.percona.com/downloads/TESTING/pmm/percona-qan-app-1.0.4.tar.gz \
    /opt/
RUN mkdir qan-api && \
        tar zxf percona-qan-api-1.0.5-20160926.920a49c-x86_64.tar.gz --strip-components=1 -C qan-api && \
        mkdir qan-app && \
        tar zxf percona-qan-app-1.0.4.tar.gz --strip-components=1 -C qan-app && \
	/opt/qan-install.sh

# ##### #
# Start #
# ##### #
CMD ["/opt/entrypoint.sh"]
