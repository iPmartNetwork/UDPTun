
# UDP Tunnel VPN

A simple, robust, and production-ready UDP-based TUN/TAP VPN tunnel for Linux.  
**Supports auto systemd integration, live log/status, interactive menu, and runs on Python 3.**

## ⭐ Features

- Easy menu-driven Bash manager (no manual config needed)
- Run as server or client, both with systemd auto-restart
- Live status & logs for server/client
- Auto installation of requirements (Python3)
- All traffic goes through a TUN interface (virtual point-to-point network)
- Minimal dependencies — works on almost any modern VPS
- Secure shared password (customizable)
- Designed for reliability and simplicity

## ⚡ Requirements

- Two Linux servers (root access, TUN/TAP enabled)
- Python 3 (auto-installed if missing)
- Open UDP port for tunnel traffic

## 🚀 Quick Start

Clone/download the repo and copy both files (`udptun.py`, `udptun-manager.sh`) to **both servers**.

```bash
chmod +x udptun-manager.sh
sudo ./udptun-manager.sh
```
> Always run as root (sudo).

The menu lets you run as **server** or **client**, check status, manage logs, stop/remove services.

---

## 🌍 Example: Tunneling Between Two Servers

### Network Plan

|        | VPS A (Server) | VPS B (Client) |
|--------|----------------|---------------|
| Public IP | `1.2.3.4`       | `5.6.7.8`      |
| Tunnel IP | `10.99.99.1`    | `10.99.99.2`   |
| UDP Port  | `2222`          | `2222`         |

### 1. **On VPS A (Server)**
- Start menu:
    ```
    sudo ./udptun-manager.sh
    ```
- Choose: `1) Start as Server (systemd)`
- Enter:
    - Port: `2222`
    - Local tunnel IP: `10.99.99.1`
    - Peer tunnel IP: `10.99.99.2`

### 2. **On VPS B (Client)**
- Start menu:
    ```
    sudo ./udptun-manager.sh
    ```
- Choose: `2) Start as Client (systemd)`
- Enter:
    - Server IP: `1.2.3.4`
    - Server Port: `2222`
    - Local tunnel IP: `10.99.99.2`
    - Peer tunnel IP: `10.99.99.1`

### 3. **Check the Tunnel**

```bash
ip addr show tun0
ping 10.99.99.1     # from client
ping 10.99.99.2     # from server
```

### 4. **View Status/Logs**
From menu:
- `3) Show Server status/log`
- `4) Show Client status/log`

Or manually:
```bash
systemctl status udptun-server.service
tail -f /opt/udptun-server.log
systemctl status udptun-client.service
tail -f /opt/udptun-client.log
```

---

## 🛡️ Security

- Change the shared password in `udptun.py`!  
  Edit this line:
  ```python
  SHARED_PASSWORD = hashlib.sha256(b"ChangeThisPassword123!").digest()
  ```
- Restrict UDP port by firewall so only your VPS can connect.

---

## 🧹 Uninstall

To remove a tunnel/service, use the menu options:  
- "Stop Server/Client"
- "Remove Server/Client Service"

Or remove manually:
```bash
systemctl disable --now udptun-server.service
rm /etc/systemd/system/udptun-server.service
systemctl daemon-reload
```
And delete project files.

---

## ❓ Troubleshooting

- **Permission denied:** Run as root/sudo.
- **TUN device error:** Check VPS provider, TUN/TAP module must be enabled.
- **Port blocked:** Check firewalls/security group for UDP port.
- **No connectivity:** Double check IPs, port, and logs.

---

## 📄 License

MIT License — feel free to use, improve, or fork.

---

## 🤝 Contribution & Contact

Pull requests welcome!  
For feedback, issues, or improvements:  
[Open an issue on GitHub](https://github.com/YourRepo/UDP-Tunnel/issues)

---

> Developed by [iPmart Network](https://github.com/iPmartNetwork)  
> Inspired by Xiaoxia’s original udptun
