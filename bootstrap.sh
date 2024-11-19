#!/bin/bash

set -Eeuo pipefail

MUNIN_CONFIGURATION_FILE=/etc/munin/munin-node.conf
MUNIN_LOG_FILE=/var/log/munin/munin-node-configure.log
MUNIN_PLUGINS_BASE=/var/lib/muninplugins
MUNIN_BIND_HOST="${MUNIN_BIND_HOST:-*}"
MUNIN_BIND_PORT="${MUNIN_BIND_PORT:-4949}"
MUNIN_ALLOW="${MUNIN_ALLOW:-cidr_allow 0.0.0.0/0}"
MUNIN_PLUGIN_DOCKER_EXCLUDE="${MUNIN_PLUGIN_DOCKER_EXCLUDE:-}"
ROOTFS_PATH="${ROOTFS_PATH:-/rootfs}"


# Configure binding
sed \
    -e 's/^host .*$/host '"${MUNIN_BIND_HOST}"'/' \
    -i "${MUNIN_CONFIGURATION_FILE}"
sed \
    -e 's/^port .*$/port '"${MUNIN_BIND_PORT}"'/' \
    -i "${MUNIN_CONFIGURATION_FILE}"

# Configure allow/deny
sed '/^# ALLOW$/,$d' -i /etc/munin/munin-node.conf
cat <<EOF >> /etc/munin/munin-node.conf
# ALLOW
${MUNIN_ALLOW}
EOF

# Configure Docker plugin
DOCKER_CONF="/etc/munin/plugin-conf.d/docker"
cat <<EOF > "${DOCKER_CONF}"
[docker_*]
#group docker
env.DOCKER_HOST unix://${ROOTFS_PATH}/run/docker.sock
EOF

docker context create docker-rootfs --docker "host=unix:///rootfs/run/docker.sock"
docker context use docker-rootfs

if [ -n "${MUNIN_PLUGIN_DOCKER_EXCLUDE}" ]
then
    echo "env.EXCLUDE_CONTAINER_NAME ${MUNIN_PLUGIN_DOCKER_EXCLUDE}" \
        >> "${DOCKER_CONF}"
fi

# Configure automatic plugins
munin-node-configure --shell | bash || true

# if /var/lib/muninplugins/ do exist, soft link to /etc/munin/plugins
if [ -d "${MUNIN_PLUGINS_BASE}" ]
then
    readarray -d PLUGINS \
        < <(ls -1 "${MUNIN_PLUGINS_BASE}" )
    for plugin in "${PLUGINS[@]}"
    do
        if [ ! -f "/etc/munin/plugins/${plugin}" ]
        then
            ln -vs \
                "${MUNIN_PLUGINS_BASE}/${plugin}" \
                "/etc/munin/plugins/${plugin}"
        fi
    done
fi

/etc/init.d/munin-node start
exec tail -f "${MUNIN_LOG_FILE}"
