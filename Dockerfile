FROM ubuntu:22.04

RUN \
    apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
        munin-node \
	munin-plugins \
	munin-plugins-extra \
	ca-certificates \
	curl \
        dnsutils \
	gnupg \
	lsb-release \
        mtr \
	python3-docker \
        telnet \
        wget \
        && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y docker-ce-cli && \
    apt-get clean && \
    rm -rf \
        /var/cache/apt/archives/* \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/*

RUN git clone "https://github.com/munin-monitoring/contrib.git" && \
    cp -rv \
        contrib/plugins/docker/docker_* \
	/usr/share/munin/plugins/ \
    && \
    rm -Rfv contrib

ADD ./plugins/* /usr/share/munin/plugins/

RUN ln -s \
        /usr/share/munin/plugins/cpu_by_process \
        /etc/munin/plugins/cpu_by_process && \
    ln -s \
        /usr/share/munin/plugins/docker_ \
        /etc/munin/plugins/docker_multi && \
    mkdir -p /var/log/munin/ && \
    chown -R munin:munin /var/log/munin/

ADD bootstrap.sh /bootstrap.sh

CMD ["/bootstrap.sh"]
