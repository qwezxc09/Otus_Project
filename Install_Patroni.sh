
-- Устанавливаем Patroni:
for i in {1..3}; do vm_ip_address=$(yc compute instance show --name ubuntu$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') &&
 ssh -o StrictHostKeyChecking=no -i ~/.ssh/yc_key yc-user@$vm_ip_address 'sudo apt install -y python3 python3-pip git mc &&
  sudo pip3 install psycopg2-binary && sudo systemctl stop postgresql@14-main && sudo -u postgres pg_dropcluster 14 main &&
   sudo pip3 install patroni[consul] && sudo ln -s /usr/local/bin/patroni /bin/patroni' & done;

-- Устанавливаем Patroni как сервис

for i in {1..3}; do vm_ip_address=$(yc compute instance show --name ubuntu$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') &&
 ssh -o StrictHostKeyChecking=no -i ~/.ssh/yc_key yc-user@$vm_ip_address 'cat > temp.cfg << EOF 
[Unit]
Description=High availability PostgreSQL Cluster
After=syslog.target network.target
[Service]
Type=simple
User=postgres
Group=postgres
ExecStart=/usr/local/bin/patroni /etc/patroni.yml
KillMode=process
TimeoutSec=30
Restart=no
[Install]
WantedBy=multi-user.target
EOF
cat temp.cfg | sudo tee -a /etc/systemd/system/patroni.service
' & done;

for i in {1..3}; do vm_ip_address=$(yc compute instance show --name ubuntu$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') &&
 ssh -o StrictHostKeyChecking=no -i ~/.ssh/yc_key yc-user@$vm_ip_address 'cat > temp2.cfg << EOF 
scope: patroni
name: $(hostname)
restapi:
  listen: $(hostname -I | tr -d " "):8008
  connect_address: $(hostname -I | tr -d " "):8008
consul:
  host: "localhost:8500"
  register_service: true
  #token: <consul-acl-token>
bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      parameters:
  initdb: 
  - encoding: UTF8
  - data-checksums
  pg_hba: 
  - host replication replicator 10.0.0.0/24 md5
  - host all all 10.0.0.0/24 md5
  - host all all 0.0.0.0/0 trust
  - host all all ::/0 trust
  users:
    admin:
      password: admin_321
      options:
        - createrole
        - createdb
postgresql:
  listen: 127.0.0.1, $(hostname -I | tr -d " "):5432
  connect_address: $(hostname -I | tr -d " "):5432
  data_dir: /var/lib/postgresql/14/main
  bin_dir: /usr/lib/postgresql/14/bin
  pgpass: /tmp/pgpass0
  authentication:
    replication:
      username: replicator
      password: rep-pass_321
    superuser:
      username: postgres
      password: postgres
    rewind:  
      username: rewind_user
      password: rewind_password_321
  parameters:
    unix_socket_directories: '.'
tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false
EOF
cat temp2.cfg | sudo tee -a /etc/patroni.yml
' & done;

-- Запуск Patroni

vm_ip_address=$(yc compute instance show --name ubuntu1 | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i ~/.ssh/yc_key yc-user@$vm_ip_address
sudo systemctl enable patroni && sudo systemctl start patroni 
sudo patronictl -c /etc/patroni.yml list 

vm_ip_address=$(yc compute instance show --name ubuntu2 | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i ~/.ssh/yc_key yc-user@$vm_ip_address
sudo systemctl enable patroni && sudo systemctl start patroni 
sudo patronictl -c /etc/patroni.yml list 

vm_ip_address=$(yc compute instance show --name ubuntu3 | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i ~/.ssh/yc_key yc-user@$vm_ip_address
sudo systemctl enable patroni && sudo systemctl start patroni 
sudo patronictl -c /etc/patroni.yml list 