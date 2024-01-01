#!/bin/bash
yay -S --noconfirm taskd
#configure
export TASKDDATA=/var/lib/taskd
# Move to the directory containing the certificate generation scripts
cd /usr/share/doc/taskd/pki/
# Edit the vars file
# Make sure to replace 'your_server_name' with your actual server name or IP address
sed -i 's/CN=.*/CN=your_server_name/' vars
# Generate self-signed certificates
./generate
# Copy generated certificates to Taskserver directory
cp *.pem /var/lib/taskd/
# Configure Taskserver
cat <<EOL > /var/lib/taskd/config
client.cert=/var/lib/taskd/client.cert.pem
client.key=/var/lib/taskd/client.key.pem
server.cert=/var/lib/taskd/server.cert.pem
server.key=/var/lib/taskd/server.key.pem
server.crl=/var/lib/taskd/server.crl.pem
ca.cert=/var/lib/taskd/ca.cert.pem
EOL
# Set permissions for certificates
chown taskd:taskd /var/lib/taskd/*.pem
chmod 400 /var/lib/taskd/*.pem
# Change Taskserver log location
touch /var/log/taskd.log
chown taskd:taskd /var/log/taskd.log
taskd config --force log /var/log/taskd.log
# Set Taskserver name and port (replace 'your_server_name' and 'your_port' accordingly)
taskd config --force server your_server_name:your_port
# Start and enable Taskserver service
systemctl start taskd.service
systemctl enable taskd.service
# Add a user to Taskserver (replace 'your_group' and 'your_username' accordingly)
taskd add org your_group
taskd add user your_group your_username
# Set permissions for the new group and user
chown -R taskd:taskd /var/lib/taskd/orgs
# Generate client certificates for the user
./generate.client your_username
# Copy client certificates to the user's Taskwarrior data directory (replace 'your_username' accordingly)
cp *.pem ~/.task/
# Configure Taskwarrior for the user
cat <<EOL > ~/.task/config
taskd.server=your_server_name:your_port
taskd.credentials=your_group/your_username/key
taskd.certificate=~/.task/your_username.cert.pem
taskd.key=~/.task/your_username.key.pem
taskd.ca=~/.task/ca.cert.pem
EOL
# Perform initial synchronization
task sync init
# Send local changes to the server
task sync
