
-- установка PostgreSQL на 3 ВМ:
for i in {1..3}; do vm_ip_address=$(yc compute instance show --name ubuntu$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') &&
 ssh -o StrictHostKeyChecking=no -i ~/.ssh/yc_key yc-user@$vm_ip_address 'sudo apt update &&
  sudo apt upgrade -y -q && echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" |
   sudo tee -a /etc/apt/sources.list.d/pgdg.list && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc |
    sudo apt-key add - && sudo apt-get update && sudo apt -y install postgresql-14' & done;

-- убедимся, что кластера Постгреса стартовали
for i in {1..3}; do vm_ip_address=$(yc compute instance show --name ubuntu$i | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i ~/.ssh/yc_key yc-user@$vm_ip_address 'hostname; pg_lsclusters' & done;
