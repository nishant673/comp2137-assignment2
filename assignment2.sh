#!/bin/bash
# ==========================
# Assignment 2 Script
# Configures server1 as required
# ==========================

echo "========== Assignment 2 Script Started =========="

# 1️⃣ Configure network (persistent)
NETPLAN_FILE="/etc/netplan/00-installer-config.yaml"
IP_ADDR="192.168.16.21/24"

if ! grep -q "$IP_ADDR" $NETPLAN_FILE 2>/dev/null; then
    echo "Updating netplan for $IP_ADDR..."
    sudo tee $NETPLAN_FILE > /dev/null <<EOF
network:
  version: 2
  ethernets:
    eth1:
      addresses: [$IP_ADDR]
      dhcp4: no
EOF
    sudo netplan apply
else
    echo "Network already configured with $IP_ADDR"
fi

# 2️⃣ Update /etc/hosts
if ! grep -q "192.168.16.21 server1" /etc/hosts; then
    echo "192.168.16.21 server1" | sudo tee -a /etc/hosts
else
    echo "/etc/hosts already has correct entry"
fi

# 3️⃣ Install Apache2 and Squid
for pkg in apache2 squid; do
    if ! dpkg -l | grep -q "$pkg"; then
        echo "Installing $pkg..."
        sudo apt update
        sudo apt install -y $pkg
    else
        echo "$pkg already installed"
    fi
done

# 4️⃣ Start and enable services
for svc in apache2 squid; do
    sudo systemctl enable $svc
    sudo systemctl restart $svc
    echo "$svc service running"
done

# 5️⃣ Create users and setup SSH keys
USER_LIST=(dennis aubrey captain snibbles brownie scooter sandy perrier cindy tiger yoda)
DENNIS_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

for user in "${USER_LIST[@]}"; do
    if ! id "$user" &>/dev/null; then
        sudo useradd -m -s /bin/bash "$user"
        echo "User $user created"
    else
        echo "User $user already exists"
    fi

    # Setup SSH keys
    SSH_DIR="/home/$user/.ssh"
    sudo mkdir -p $SSH_DIR
    sudo chmod 700 $SSH_DIR
    sudo touch $SSH_DIR/authorized_keys
    sudo chmod 600 $SSH_DIR/authorized_keys

    if [ "$user" == "dennis" ]; then
        if ! grep -q "$DENNIS_KEY" $SSH_DIR/authorized_keys; then
            echo "$DENNIS_KEY" | sudo tee -a $SSH_DIR/authorized_keys
        fi
        sudo usermod -aG sudo dennis
    fi

    sudo chown -R $user:$user $SSH_DIR
done

# 6️⃣ Test Squid proxy
if curl -I -x http://127.0.0.1:3128 http://example.com &>/dev/null; then
    echo "Squid proxy test successful"
else
    echo "Squid proxy test FAILED"
fi

# 7️⃣ Test Apache
if curl -I http://127.0.0.1 &>/dev/null; then
    echo "Apache is serving pages correctly"
else
    echo "Apache test FAILED"
fi

echo "========== Assignment 2 Script Completed =========="
