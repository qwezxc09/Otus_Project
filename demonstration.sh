
vm_ip_address=$(yc compute instance show --name ubuntu1 | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i ~/.ssh/yc_key yc-user@$vm_ip_address

vm_ip_address=$(yc compute instance show --name ubuntu2 | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i ~/.ssh/yc_key yc-user@$vm_ip_address

vm_ip_address=$(yc compute instance show --name ubuntu3 | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i ~/.ssh/yc_key yc-user@$vm_ip_address

-- Плановое переключение:
patronictl -c /etc/patroni.yml switchover patroni

sudo patronictl -c /etc/patroni.yml list 

psql -h 130.193.39.211 -p 5000 -U postgres otus

psql -h 130.193.39.211 -p 5001 -U postgres otus

CREATE SCHEMA otus;