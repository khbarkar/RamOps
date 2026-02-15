#!/usr/bin/env bash
set -euo pipefail

BROKER_ID=$1
BROKER_IP=$2

echo "=== Provisioning Kafka Broker $BROKER_ID ==="

# Update and install dependencies
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y openjdk-17-jre-headless wget curl

# Install Kafka (KRaft mode, no Zookeeper)
KAFKA_VERSION="3.6.1"
SCALA_VERSION="2.13"
cd /opt
wget -q https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz
tar -xzf kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz
mv kafka_${SCALA_VERSION}-${KAFKA_VERSION} kafka
rm kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz

# Format the slow disk and mount it
if [ -b /dev/sdc ]; then
    mkfs.ext4 -F /dev/sdc
    mkdir -p /mnt/kafka-logs
    mount /dev/sdc /mnt/kafka-logs
    echo "/dev/sdc /mnt/kafka-logs ext4 defaults 0 2" >> /etc/fstab

    # Apply I/O throttle (10MB/s write limit)
    echo "8:32 10485760" > /sys/fs/cgroup/blkio/blkio.throttle.write_bps_device
fi

# Generate cluster ID (same for all brokers)
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

log.dirs=/mnt/kafka-logs
num.network.threads=8
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600

num.partitions=24
num.recovery.threads.per.data.dir=1
offsets.topic.replication.factor=3
transaction.state.log.replication.factor=3
transaction.state.log.min.isr=2

log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000

# Make disk bottleneck more visible
log.flush.interval.messages=1000
log.flush.interval.ms=1000
EOF

# Format log directory
/opt/kafka/bin/kafka-storage.sh format -t ${CLUSTER_ID} -c /opt/kafka/config/kraft/server.properties

# Create systemd service
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

# Install JMX Exporter for Prometheus
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
- pattern: kafka.server<type=(.+), name=(.+), clientId=(.+), brokerHost=(.+), brokerPort=(.+)><>Value
  name: kafka_server_$1_$2
  type: GAUGE
  labels:
    clientId: "$3"
    broker: "$4:$5"
EOF

# Update systemd service to include JMX exporter
sed -i 's|ExecStart=/opt/kafka/bin/kafka-server-start.sh|Environment="KAFKA_OPTS=-javaagent:/opt/kafka/jmx_prometheus_javaagent-0.20.0.jar=7071:/opt/kafka/jmx_exporter.yml"\nExecStart=/opt/kafka/bin/kafka-server-start.sh|' /etc/systemd/system/kafka.service

systemctl daemon-reload
systemctl enable kafka
systemctl start kafka

echo "Kafka Broker $BROKER_ID provisioned successfully"
