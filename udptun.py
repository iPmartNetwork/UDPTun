#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
    UDP Tunnel VPN (Python 3)
    Enhanced and rewritten for professional use
    Author: iPmart (Based on original Xiaoxia version)
"""

import os, sys, hashlib, struct, socket, select, pickle, fcntl, logging

# === CONFIGURATION ===
SHARED_PASSWORD = hashlib.sha256(b"ChangeThisPassword123!").digest()  # Change the password!
TUNSETIFF = 0x400454ca
IFF_TUN   = 0x0001 | 0x1000 # TUN + NO_PI

BUFFER_SIZE = 8192
MTU = 1400

logging.basicConfig(level=logging.INFO, format="[%(asctime)s] %(levelname)s: %(message)s")

def create_tun(name='tun%d'):
    tun_fd = os.open("/dev/net/tun", os.O_RDWR)
    ifs = fcntl.ioctl(tun_fd, TUNSETIFF, struct.pack("16sH", name.encode(), IFF_TUN))
    tun_name = ifs[:16].strip(b"\x00").decode()
    return tun_fd, tun_name

def config_tun(tun_name, ip, peer, mtu):
    # Uses 'ip' instead of ifconfig
    os.system(f"ip addr add {ip}/30 peer {peer} dev {tun_name}")
    os.system(f"ip link set {tun_name} mtu {mtu} up")

def safe_pickle_serialize(obj):
    # NOTE: In real world use encryption (AES, etc.) in addition to pickle
    return pickle.dumps(obj, protocol=pickle.HIGHEST_PROTOCOL)

def safe_pickle_deserialize(data):
    return pickle.loads(data)

def tun_read(tun_fd):
    return os.read(tun_fd, BUFFER_SIZE)

def tun_write(tun_fd, data):
    return os.write(tun_fd, data)

def udp_send(sock, data, addr):
    sock.sendto(data, addr)

def udp_recv(sock):
    return sock.recvfrom(BUFFER_SIZE)

def server(port, tun_ip, tun_peer):
    tun_fd, tun_name = create_tun()
    config_tun(tun_name, tun_ip, tun_peer, MTU)
    logging.info(f"Tunnel created: {tun_name} ({tun_ip} <-> {tun_peer})")

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(('0.0.0.0', port))
    sock.setblocking(False)
    client_addr = None

    while True:
        rlist, _, _ = select.select([sock, tun_fd], [], [], 1)
        for s in rlist:
            if s == sock:
                data, addr = udp_recv(sock)
                try:
                    packet = safe_pickle_deserialize(data)
                except Exception as e:
                    logging.warning(f"Invalid packet from {addr}: {e}")
                    continue

                if packet.get('password') != SHARED_PASSWORD:
                    logging.warning(f"Auth failed from {addr}")
                    continue

                if 'tun_data' in packet:
                    tun_write(tun_fd, packet['tun_data'])
                    client_addr = addr
            elif s == tun_fd and client_addr:
                tun_data = tun_read(tun_fd)
                payload = safe_pickle_serialize({'password': SHARED_PASSWORD, 'tun_data': tun_data})
                udp_send(sock, payload, client_addr)

def client(server_ip, port, tun_ip, tun_peer):
    tun_fd, tun_name = create_tun()
    config_tun(tun_name, tun_ip, tun_peer, MTU)
    logging.info(f"Tunnel created: {tun_name} ({tun_ip} <-> {tun_peer})")

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    server_addr = (server_ip, port)

    while True:
        rlist, _, _ = select.select([sock, tun_fd], [], [], 1)
        for s in rlist:
            if s == tun_fd:
                tun_data = tun_read(tun_fd)
                payload = safe_pickle_serialize({'password': SHARED_PASSWORD, 'tun_data': tun_data})
                udp_send(sock, payload, server_addr)
            elif s == sock:
                data, _ = udp_recv(sock)
                try:
                    packet = safe_pickle_deserialize(data)
                    if packet.get('password') == SHARED_PASSWORD and 'tun_data' in packet:
                        tun_write(tun_fd, packet['tun_data'])
                except Exception as e:
                    logging.warning(f"Invalid packet from server: {e}")

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description="UDP Tunnel VPN")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--server', type=int, help="Run as server on port")
    group.add_argument('--client', type=str, help="Run as client, server_ip:port")
    parser.add_argument('--local', type=str, required=True, help="Tunnel local IP")
    parser.add_argument('--peer', type=str, required=True, help="Tunnel peer IP")
    args = parser.parse_args()

    if args.server:
        server(args.server, args.local, args.peer)
    elif args.client:
        ip, port = args.client.split(':')
        client(ip, int(port), args.local, args.peer)
