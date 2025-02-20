-- Создаем сетевую инфраструктуру:

-- Создаем сеть
yc vpc network create \
    --name otus-net \
    --description "otus-net" 

-- Просматрвиаем созданные сети
yc vpc network list

-- Создаем подсеть
yc vpc subnet create \
    --name otus-subnet \
    --range 10.0.0.0/24 \
    --network-name otus-net \
    --description "otus-subnet" 

-- Просматрвиаем созданные подсети
yc vpc subnet list

-- Создам DNS
yc dns zone create --name otus-dns \
--zone staging. \
--private-visibility network-ids=enph1q824dgidfkgfqp8

-- Просматрвиаем созданную зону
yc dns zone list

-- Разворачиваем 3 ВМ для PostgreSQL:
for i in {4..4}; do yc compute instance create --name ubuntu$i --hostname ubuntu$i --cores 2 --memory 4 --create-boot-disk size=10G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2004-lts --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 --ssh-key ~/.ssh/yc_key.pub & done;

-- Разворачиваем виртуальную машину для HaProxy
yc compute instance create --name haproxy --hostname haproxy --cores 2 --memory 4 --create-boot-disk size=10G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2004-lts --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 --ssh-key ~/.ssh/yc_key.pub

-- Просматриваем созданные ВМ
yc compute instances list

