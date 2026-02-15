#!/usr/bin/env python3
"""
Kafka load generator for disk-bound broker scenario.
Generates high-throughput writes to expose I/O bottlenecks.
"""
import argparse
import json
import time
import sys
from kafka import KafkaProducer, KafkaConsumer
from kafka.admin import KafkaAdminClient, NewTopic
from kafka.errors import TopicAlreadyExistsError
import threading


def create_topic(bootstrap_servers, topic, partitions=24, replication=3):
    """Create topic if it doesn't exist"""
    admin = KafkaAdminClient(bootstrap_servers=bootstrap_servers)
    try:
        topic_list = [NewTopic(name=topic, num_partitions=partitions, replication_factor=replication)]
        admin.create_topics(new_topics=topic_list, validate_only=False)
        print(f"Created topic: {topic} (partitions={partitions}, replication={replication})")
    except TopicAlreadyExistsError:
        print(f"Topic {topic} already exists")
    finally:
        admin.close()


def produce_messages(bootstrap_servers, topic, msg_size=1024, target_mbps=100, duration=300):
    """Produce messages at target throughput"""
    producer = KafkaProducer(
        bootstrap_servers=bootstrap_servers,
        batch_size=32768,
        linger_ms=10,
        compression_type='lz4',
        acks='all',
        retries=10
    )

    payload = 'x' * msg_size
    msgs_per_sec = (target_mbps * 1024 * 1024) // msg_size
    interval = 1.0 / msgs_per_sec

    start_time = time.time()
    sent = 0
    errors = 0

    print(f"Producing {msgs_per_sec} msgs/sec ({target_mbps} MB/s) for {duration}s...")

    try:
        while time.time() - start_time < duration:
            loop_start = time.time()

            try:
                future = producer.send(topic, value=payload.encode('utf-8'))
                sent += 1

                if sent % 1000 == 0:
                    elapsed = time.time() - start_time
                    rate = sent / elapsed
                    print(f"[Producer] Sent {sent} msgs ({rate:.1f} msg/s, {rate * msg_size / 1024 / 1024:.1f} MB/s)")
            except Exception as e:
                errors += 1
                if errors % 100 == 0:
                    print(f"[Producer] Errors: {errors}")

            # Throttle to target rate
            sleep_time = interval - (time.time() - loop_start)
            if sleep_time > 0:
                time.sleep(sleep_time)

    except KeyboardInterrupt:
        print("\nStopping producer...")
    finally:
        producer.flush()
        producer.close()
        elapsed = time.time() - start_time
        print(f"[Producer] Sent {sent} messages in {elapsed:.1f}s ({sent/elapsed:.1f} msg/s)")
        print(f"[Producer] Errors: {errors}")


def consume_messages(bootstrap_servers, topic, group_id, duration=300):
    """Consume messages and track lag"""
    consumer = KafkaConsumer(
        topic,
        bootstrap_servers=bootstrap_servers,
        group_id=group_id,
        auto_offset_reset='earliest',
        enable_auto_commit=True,
        max_poll_records=500,
        fetch_max_bytes=52428800  # 50MB
    )

    start_time = time.time()
    consumed = 0

    print(f"Consuming from {topic} (group: {group_id}) for {duration}s...")

    try:
        while time.time() - start_time < duration:
            msgs = consumer.poll(timeout_ms=1000)
            for partition, records in msgs.items():
                consumed += len(records)

            if consumed > 0 and consumed % 1000 == 0:
                elapsed = time.time() - start_time
                rate = consumed / elapsed
                print(f"[Consumer] Consumed {consumed} msgs ({rate:.1f} msg/s)")

    except KeyboardInterrupt:
        print("\nStopping consumer...")
    finally:
        consumer.close()
        elapsed = time.time() - start_time
        print(f"[Consumer] Consumed {consumed} messages in {elapsed:.1f}s ({consumed/elapsed:.1f} msg/s)")


def main():
    parser = argparse.ArgumentParser(description='Kafka load generator')
    parser.add_argument('--mode', choices=['produce', 'consume', 'both'], default='both')
    parser.add_argument('--brokers', default='192.168.56.11:9092,192.168.56.12:9092,192.168.56.13:9092')
    parser.add_argument('--topic', default='high-throughput')
    parser.add_argument('--msg-size', type=int, default=1024, help='Message size in bytes')
    parser.add_argument('--target-mbps', type=int, default=100, help='Target throughput in MB/s')
    parser.add_argument('--duration', type=int, default=300, help='Duration in seconds')
    parser.add_argument('--group-id', default='test-consumer-group')

    args = parser.parse_args()

    # Create topic
    create_topic(args.brokers.split(','), args.topic)

    time.sleep(3)  # Wait for topic to propagate

    if args.mode == 'produce':
        produce_messages(args.brokers.split(','), args.topic, args.msg_size, args.target_mbps, args.duration)
    elif args.mode == 'consume':
        consume_messages(args.brokers.split(','), args.topic, args.group_id, args.duration)
    elif args.mode == 'both':
        # Run producer and consumer in parallel
        producer_thread = threading.Thread(
            target=produce_messages,
            args=(args.brokers.split(','), args.topic, args.msg_size, args.target_mbps, args.duration)
        )
        consumer_thread = threading.Thread(
            target=consume_messages,
            args=(args.brokers.split(','), args.topic, args.group_id, args.duration)
        )

        producer_thread.start()
        time.sleep(5)  # Let producer start first
        consumer_thread.start()

        producer_thread.join()
        consumer_thread.join()


if __name__ == '__main__':
    main()
