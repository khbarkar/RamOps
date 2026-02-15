#!/usr/bin/env bash
set -euo pipefail

echo "=== Provisioning Monitoring (Prometheus + Grafana) ==="

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y wget curl apt-transport-https software-properties-common

# Install Prometheus
PROM_VERSION="2.48.0"
cd /opt
wget -q https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz
tar -xzf prometheus-${PROM_VERSION}.linux-amd64.tar.gz
mv prometheus-${PROM_VERSION}.linux-amd64 prometheus
rm prometheus-${PROM_VERSION}.linux-amd64.tar.gz

# Configure Prometheus
cat > /opt/prometheus/prometheus.yml <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'kafka'
    static_configs:
      - targets:
        - '192.168.56.11:7071'
        - '192.168.56.12:7071'
        - '192.168.56.13:7071'
        labels:
          cluster: 'ramops'
EOF

# Create Prometheus systemd service
cat > /etc/systemd/system/prometheus.service <<'EOF'
[Unit]
Description=Prometheus
After=network.target

[Service]
Type=simple
User=root
ExecStart=/opt/prometheus/prometheus --config.file=/opt/prometheus/prometheus.yml --storage.tsdb.path=/opt/prometheus/data
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus

# Install Grafana
wget -q -O /usr/share/keyrings/grafana.gpg https://apt.grafana.com/gpg.key
echo "deb [signed-by=/usr/share/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list
apt-get update
apt-get install -y grafana

# Configure Grafana datasource
mkdir -p /etc/grafana/provisioning/datasources
cat > /etc/grafana/provisioning/datasources/prometheus.yml <<'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
EOF

# Install Kafka dashboard
mkdir -p /etc/grafana/provisioning/dashboards
cat > /etc/grafana/provisioning/dashboards/kafka.yml <<'EOF'
apiVersion: 1
providers:
  - name: 'Kafka'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    options:
      path: /var/lib/grafana/dashboards
EOF

mkdir -p /var/lib/grafana/dashboards

# Download popular Kafka Grafana dashboard
wget -q -O /var/lib/grafana/dashboards/kafka-overview.json https://grafana.com/api/dashboards/7589/revisions/5/download

systemctl enable grafana-server
systemctl start grafana-server

echo "Monitoring provisioned successfully"
echo "Grafana: http://192.168.56.20:3000 (admin/admin)"
echo "Prometheus: http://192.168.56.20:9090"
