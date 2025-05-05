#!/bin/bash

echo "[+] Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "[+] Installing vulnerable services and dependencies..."
sudo apt install -y apache2 apache2-utils openssh-server mysql-server php libapache2-mod-php php-mysql netcat nmap python3 python3-pip

echo "[+] Enabling and starting services..."
sudo systemctl enable apache2 ssh mysql
sudo systemctl start apache2 ssh mysql

echo "[+] Creating weak user 'sydney' with password '12345'..."
sudo useradd -m sydney
echo "sydney:12345" | sudo chpasswd
sudo usermod -aG sudo sydney

echo "[+] Enabling SSH root login for brute-force simulation..."
sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh

echo "[+] Weakening MySQL security with default creds..."
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root'; FLUSH PRIVILEGES;"

echo "[+] Creating vulnerable PHP web app with hardcoded credentials..."
sudo mkdir -p /var/www/html/vulnweb
cat <<EOF | sudo tee /var/www/html/vulnweb/index.php
<?php
\$user = \$_POST['user'] ?? '';
\$pass = \$_POST['pass'] ?? '';

if (\$user === 'admin' && \$pass === 'admin123') {
    echo "Welcome, admin!";
} else {
    echo "<form method='POST'>
        Username: <input name='user'><br>
        Password: <input name='pass' type='password'><br>
        <input type='submit' value='Login'>
    </form>";
}
?>
EOF

echo "[+] Setting permissions..."
sudo chown -R www-data:www-data /var/www/html/vulnweb

echo "[+] Enabling outdated Apache modules..."
sudo a2enmod php7.4
sudo systemctl restart apache2

echo "[+] Deploying test Flask app on port 5000..."
pip3 install flask >/dev/null 2>&1
cat <<EOF > ~/app.py
from flask import Flask
app = Flask(__name__)

@app.route("/")
def home():
    return "Test Flask App - Vulnerable Setup"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF

echo "[+] Setup Complete!"
echo "[*] Services running:"
echo "   - SSH:        ssh sydney@<target-ip> (password: 12345)"
echo "   - MySQL:      root / root"
echo "   - Web Login:  http://<target-ip>/vulnweb (admin / admin123)"
echo "   - Flask App:  python3 ~/app.py"
