#!/bin/bash
#-------------------------
# Install etcd
#-------------------------
ETCD_VER=v3.4.3
BASE_DOWNLOAD_URL=https://github.com/etcd-io/etcd/releases/download
DOWNLOAD_URL="${BASE_DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz"

TMP_DIR="/tmp/etcd-${ETCD_VER}"
INSTALL_DIR="/opt/etcd"
BIN_DIR="${INSTALL_DIR}/bin"

mkdir -p "${TMP_DIR}"
mkdir -p "${BIN_DIR}"

echo "etcd-${ETCD_VER}" > "${INSTALL_DIR}/version.info"

echo "Downloading pre-built etcd binary from ${DOWNLOAD_URL}"
curl -L "${DOWNLOAD_URL}" -o "${TMP_DIR}/etcd-${ETCD_VER}-linux-amd64.tar.gz"
tar xzf "${TMP_DIR}/etcd-${ETCD_VER}-linux-amd64.tar.gz" -C "${TMP_DIR}" --strip-components=1

echo "Installing etcd into ${INSTALL_DIR}"
cp -p "${TMP_DIR}/etcd" "${BIN_DIR}"
cp -p "${TMP_DIR}/etcdctl" "${BIN_DIR}"

rm -rf "${TMP_DIR}"

#-------------------------
# Add etcd to systemctl
#-------------------------
PUBLIC_HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/public-hostname)

cat > /etc/etcd.conf <<EOL
ETCD_ENABLE_V2=1
ETCD_DATA_DIR=/var/lib/etcd
ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379,http://127.0.0.1:4001
ETCD_ADVERTISE_CLIENT_URLS=http://${PUBLIC_HOSTNAME}:2379
EOL

cat > /etc/systemd/system/etcd.service <<EOL
[Unit]
Description=etcd server
Documentation=https://github.com/etcd-io/etcd
After=network.target

[Service]
Type=notify
EnvironmentFile=/etc/etcd.conf
ExecStartPre=/bin/mkdir -p /var/lib/etcd
ExecStart=/opt/etcd/bin/etcd
Restart=always
RestartSec=2
LimitNOFILE=40000
StartLimitBurst=5
StartLimitInterval=30s
KillMode=process

[Install]
WantedBy=multi-user.target
EOL

#-------------------------
# Enable and start etcd
#-------------------------
systemctl enable etcd
systemctl start etcd

