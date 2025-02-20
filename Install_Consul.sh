-- Разбрасываем бинарник на все машины:
for i in {1..3}; do vm_ip_address=$(yc compute instance show --name ubuntu$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') && 
scp -o StrictHostKeyChecking=no -i ~/.ssh/yc_key ~/consul/consul yc-user@$vm_ip_address:/tmp && 
ssh -o StrictHostKeyChecking=no -i ~/.ssh/yc_key yc-user@$vm_ip_address 'sudo mv /tmp/consul /usr/bin/ && 
chmod +x /usr/bin/consul && sudo mkdir -p /var/lib/consul /etc/consul.d && sudo chown yc-user:yc-user /var/lib/consul /etc/consul.d &&
 sudo chmod 775 /var/lib/consul /etc/consul.d' & done;

 -- Сгенерируем ключ для консула на любой из нод кластера:
 ssh -i ~/.ssh/yc_key yc-user@51.250.82.107 
 consul keygen 

for i in {1..3}; do vm_ip_address=$(yc compute instance show --name ubuntu$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') &&
 ssh -o StrictHostKeyChecking=no -i ~/.ssh/yc_key yc-user@$vm_ip_address 'cat > temp.cfg << EOF 
{
    "bind_addr": "0.0.0.0",
    "bootstrap_expect": 3,
    "client_addr": "0.0.0.0",
    "data_dir": "/var/lib/consul",
    "enable_script_checks": true,
    "dns_config": {
        "enable_truncate": true,
        "only_passing": true
    },
    "enable_syslog": true,
    "encrypt": "iu3K/wZdrbAN3YEu9jlGzim8/0C/BZgqVKXpYDb4A+U=",
    "leave_on_terminate": true,
    "log_level": "INFO",
    "rejoin_after_leave": true,
    "retry_join": [
        "ubuntu1",
        "ubuntu2",
        "ubuntu3"
    ],
    "server": true,
    "start_join": [
        "ubuntu1",
        "ubuntu2",
        "ubuntu3"
    ],
   "ui_config": { "enabled": true }
}
EOF
cat temp.cfg | sudo tee -a /etc/consul.d/config.json
' & done;

-- Проверяем корректность конфигурационного файла:
consul validate /etc/consul.d/config.json

-- В завершение настройки создадим юнит в systemd для возможности автоматического запуска сервиса:
for i in {1..3}; do vm_ip_address=$(yc compute instance show --name ubuntu$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') && 
ssh -o StrictHostKeyChecking=no -i ~/.ssh/yc_key yc-user@$vm_ip_address 'cat > temp.cfg << EOF 
[Unit]
Description=Consul Service Discovery Agent
Documentation=https://www.consul.io/
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=yc-user
Group=yc-user
ExecStart=/usr/bin/consul agent \
    -node=consule_$(hostname).dmosk.local \
    -config-dir=/etc/consul.d
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
TimeoutStopSec=5
Restart=on-failure
SyslogIdentifier=consul

[Install]
WantedBy=multi-user.target
EOF
cat temp.cfg | sudo tee -a /etc/systemd/system/consul.service
' & done;

-- Перечитываем конфигурацию systemd, стартуем наш сервис, а также разрешаем автоматический старт при запуске сервера:
for i in {1..3}; do vm_ip_address=$(yc compute instance show --name ubuntu$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') &&
 ssh -o StrictHostKeyChecking=no -i ~/.ssh/yc_key yc-user@$vm_ip_address 'sudo systemctl daemon-reload && sudo systemctl start consul &&
  sudo systemctl enable consul' & done;

  -- Смотрим текущее состояние работы сервиса(мы должны увидеть состояние - Active: active (running) since ...):
for i in {1..3}; do vm_ip_address=$(yc compute instance show --name ubuntu$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i ~/.ssh/yc_key yc-user@$vm_ip_address 'hostname; sudo systemctl status consul' & done;

-- Состояние нод кластера мы можем посмотреть командой:
consul members