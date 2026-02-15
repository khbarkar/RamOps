#!/usr/bin/env bash
set -euo pipefail

BROKER_ID=$1
BROKER_IP=$2

echo "=== Provisioning Kafka Broker $BROKER_ID (Network Throttled) ==="

# Update and install dependencies
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y openjdk-17-jre-headless wget curl iproute2 iftop

# Install Kafka (KRaft mode)
KAFKA_VERSION="3.6.1"
SCALA_VERSION="2.13"
cd /opt
wget -q https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz
tar -xzf kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz
mv kafka_${SCALA_VERSION}-${KAFKA_VERSION} kafka
rm kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz

mkdir -p /var/lib/kafka-logs

# Generate cluster ID
CLUSTER_ID="MkU3OEVBNTcwNTJENDM2Qk"

# Configure Kafka
cat > /opt/kafka/config/kraft/server.properties <<EOF
process.roles=broker,controller
node.id=${BROKER_ID}
controller.quorum.voters=1@192.168.56.11:9093,2@192.168.56.12:9093,3@192.168.56.13:9093
listeners=PLAINTEXT://${BROKER_IP}:9092,CONTROLLER://${BROKER_IP}:9093
advertised.listeners=PLAINTEXT://${BROKER_IP}:9092
listener.security.protocol.map=PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT
controller.listener.names=CONTROLLER
inter.broker.listener.name=PLAINTEXT

log.dirs=/var/lib/kafka-logs
num.network.threads=8
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600

num.partitions=24
offsets.topic.replication.factor=3
transaction.state.log.replication.factor=3
transaction.state.log.min.isr=2

log.retention.hours=168
log.segment.bytes=1073741824
EOF

# Format storage
/opt/kafka/bin/kafka-storage.sh format -t ${CLUSTER_ID} -c /opt/kafka/config/kraft/server.properties

# Apply network throttling (50 Mbit/s cap on eth1)
cat > /usr/local/bin/apply-network-throttle.sh <<'THROTTLE'
#!/bin/bash
# Throttle eth1 (private network interface) to 50 Mbit/s
tc qdisc del dev eth1 root 2>/dev/null || true
tc qdisc add dev eth1 root handle 1: htb default 10
tc class add dev eth1 parent 1: classid 1:10 htb rate 50mbit ceil 50mbit
tc qdisc add dev eth1 parent 1:10 handle 10: sfq perturb 10
echo "Network throttle applied: 50 Mbit/s on eth1"
THROTTLE

chmod +x /usr/local/bin/apply-network-throttle.sh
/usr/local/bin/apply-network-throttle.sh

# Make throttle persistent across reboots
cat > /etc/systemd/system/network-throttle.service <<'EOF'
[Unit]
Description=Network Throttle for Kafka
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/apply-network-throttle.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable network-throttle

# Create Kafka systemd service
cat > /etc/systemd/system/kafka.service <<'EOF'
[Unit]
Description=Apache Kafka
After=network.target

[Service]
Type=simple
User=root
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/kraft/server.properties
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Install JMX Exporter
cd /opt/kafka
wget -q https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.20.0/jmx_prometheus_javaagent-0.20.0.jar

cat > /opt/kafka/jmx_exporter.yml <<'EOF'
lowercaseOutputName: true
lowercaseOutputLabelNames: true
rules:
- pattern: kafka.server<type=(.+), name=(.+), clientId=(.+), topic=(.+), partition=(.*)><>Value
  name: kafka_server_$1_$2
  type: GAUGE
  labels:
    clientId: "$3"
    topic: "$4"
    partition: "$5"
- pattern: kafka.server<type=(.+), name=(.+)><>Value
  name: kafka_server_$1_$2
  type: GAUGE
EOF

sed -i 's|ExecStart=/opt/kafka/bin/kafka-server-start.sh|Environment="KAFKA_OPTS=-javaagent:/opt/kafka/jmx_prometheus_javaagent-0.20.0.jar=7071:/opt/kafka/jmx_exporter.yml"\nExecStart=/opt/kafka/bin/kafka-server-start.sh|' /etc/systemd/system/kafka.service

systemctl daemon-reload
systemctl enable kafka
systemctl start kafka

echo "Kafka Broker $BROKER_ID provisioned (network throttled to 50 Mbit/s)"
