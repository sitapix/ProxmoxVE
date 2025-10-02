
# Govee2MQTT for ProxmoxVE

Bridge Govee devices to MQTT with a simple ProxmoxVE LXC container.

## Quick Start

in your proxmox host console:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/sitapix/ProxmoxVE/main/ct/govee2mqtt.sh)"
```

## Configuration

in the govee2mqtt console:
```bash
# Copy config template
cp /opt/govee2mqtt/.env.example /opt/govee2mqtt/.env

# Edit with your credentials
nano /opt/govee2mqtt/.env

# Start service
systemctl start govee2mqtt
```

## Required Settings

These are in .env.example. do the config copy above and set these
- `GOVEE_EMAIL` - Your Govee account email
- `GOVEE_PASSWORD` - Your Govee account password  
- `GOVEE_MQTT_HOST` - Your MQTT broker IP

## Access

Web interface: `http://container-ip:8056`

## Logs

```bash
journalctl -fu govee2mqtt
```
