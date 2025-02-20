
-- Установить HAProxy
sudo apt-get install haproxy

-- Изменить конфиг файл
sudo nano /etc/haproxy/haproxy.cfg

-- Запуск HAProxy
sudo systemctl start haproxy
sudo systemctl enable haproxy

-- Перезапутить виртуалку
-- Просмотр статитстики по адресу: http://89.169.156.48:7000/