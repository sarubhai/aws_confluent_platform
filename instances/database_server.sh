#!/bin/bash
# Name: database_server.sh
# Owner: Saurav Mitra
# Description: Configure containerized database server for demo

# Create SWAP space
fallocate -l 4G /swapfile 
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
sysctl vm.swappiness=10
sysctl vm.vfs_cache_pressure=50
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf


# Install Docker, Docker-compose
sudo yum -y update
sudo yum -y install yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum -y update
sudo yum -y install docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose


# Install Oracle Instant Client
cd /root
curl -L -s https://download.oracle.com/otn_software/linux/instantclient/211000/oracle-instantclient-basic-21.1.0.0.0-1.x86_64.rpm -o oracle-instantclient-basic-21.1.0.0.0-1.x86_64.rpm
curl -L -s https://download.oracle.com/otn_software/linux/instantclient/211000/oracle-instantclient-sqlplus-21.1.0.0.0-1.x86_64.rpm -o oracle-instantclient-sqlplus-21.1.0.0.0-1.x86_64.rpm
sudo yum -y install libaio
sudo rpm -ivh oracle-instantclient-basic-21.1.0.0.0-1.x86_64.rpm
sudo rpm -ivh oracle-instantclient-sqlplus-21.1.0.0.0-1.x86_64.rpm
rm -rf /root/oracle-instantclient-basic-21.1.0.0.0-1.x86_64.rpm
rm -rf /root/oracle-instantclient-sqlplus-21.1.0.0.0-1.x86_64.rpm

echo 'ORACLE_HOME=/usr/lib/oracle/21/client64' >> ~/.bash_profile 
echo 'PATH=$ORACLE_HOME/bin:$PATH' >> ~/.bash_profile
echo 'LD_LIBRARY_PATH=$ORACLE_HOME/lib' >> ~/.bash_profile
echo 'export ORACLE_HOME' >> ~/.bash_profile
echo 'export LD_LIBRARY_PATH' >> ~/.bash_profile
echo 'export PATH' >> ~/.bash_profile
source ~/.bash_profile


# Build Oracle 19c Image (oracle/database:19.3.0-ee)
cd /root
sudo yum -y install git
git clone https://github.com/oracle/docker-images.git
cd /root/docker-images/OracleDatabase/SingleInstance/dockerfiles/19.3.0
curl https://ashnik-confluent-oracle-demo.s3-us-west-2.amazonaws.com/LINUX.X64_193000_db_home.zip -o LINUX.X64_193000_db_home.zip
cd /root/docker-images/OracleDatabase/SingleInstance/dockerfiles
./buildContainerImage.sh -e -v 19.3.0 -o "--memory=4g --memory-swap=4g --build-arg SLIMMING=false" >> /root/oracleimg.log


sudo mkdir -p /opt/oracle/oradata
sudo useradd -m -d /opt/oracle/oradata -u 54321 oracle
chown -R oracle:oracle /opt/oracle

# Spawn Oracle Source Container
mkdir /root/oracle_src
cd /root/oracle_src
curl https://ashnik-confluent-oracle-demo.s3-us-west-2.amazonaws.com/oracle_src_objects.sql -o oracle_src_objects.sql
curl https://ashnik-confluent-oracle-demo.s3-us-west-2.amazonaws.com/oracle_src_data.sql -o oracle_src_data.sql
sed -i 's|PASSWORD|${db_password}|g' oracle_src_objects.sql
sudo tee /root/oracle_src/docker-compose.yml &>/dev/null <<EOF
version: "3"
services:
  oracle_src:
    image: oracle/database:19.3.0-ee
    shm_size: 1gb
    ports:
      - "1521:1521"
    environment:
      - ORACLE_PWD=${db_password}
      - ENABLE_ARCHIVELOG=true
    volumes:
      - /opt/oracle/oradata:/opt/oracle/oradata
EOF

docker-compose up -d

# Spawn Oracle Target Container
mkdir /root/oracle_tgt
cd /root/oracle_tgt
curl https://ashnik-confluent-oracle-demo.s3-us-west-2.amazonaws.com/oracle_tgt_objects.sql -o oracle_tgt_objects.sql
sed -i 's|PASSWORD|${db_password}|g' oracle_tgt_objects.sql
sudo tee /root/oracle_tgt/docker-compose.yml &>/dev/null <<EOF
version: "3"
services:
  oracle_tgt:
    image: oracle/database:19.3.0-ee
    shm_size: 1gb
    ports:
      - "1525:1521"
    environment:
      - ORACLE_PWD=${db_password}
EOF

docker-compose up -d

# Initial Database Setup
# Oracle EE 19c Source
while [ "`docker inspect -f {{.State.Health.Status}} oracle_src_oracle_src_1`" != "healthy" ]; do
  sleep 60;
done;
# SYSDBA
# sqlplus "sys/${db_password}@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=10.0.1.100)(PORT=1521))(CONNECT_DATA=(SID=ORCLCDB)))" as sysdba @/root/oracle_src/oracle_src_objects.sql



# Oracle EE 19c Target
while [ "`docker inspect -f {{.State.Health.Status}} oracle_tgt_oracle_tgt_1`" != "healthy" ]; do
  sleep 60;
done;
# SYSDBA
# sqlplus "sys/${db_password}@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=10.0.1.100)(PORT=1525))(CONNECT_DATA=(SID=ORCLCDB)))" as sysdba @/root/oracle_tgt/oracle_tgt_objects.sql


# Install MySQL Client
sudo yum -y install mysql
# Spawn MySQL/MaraiDB Container
mkdir /root/mariadb
cd /root/mariadb
# image: mariadb:latest
sudo tee /root/mariadb/docker-compose.yml &>/dev/null <<EOF
version: "3.1"
services:
  mariadb:
    image: mysql:5.7
    ports:
      - 3306:3306
    environment:
      MYSQL_ROOT_HOST: '%'
      MYSQL_ROOT_PASSWORD: ${db_password}
    command:
    - --log-bin=binlog
    - --binlog-format=ROW
    - --server-id=1
    - --sql_mode=
EOF

docker-compose up -d
# MySQL Source Database
sleep 30;

curl -L https://s3-ap-southeast-1.amazonaws.com/dwbi-datalake/dataset/showroom.sql -o showroom.sql
curl -L https://s3-ap-southeast-1.amazonaws.com/dwbi-datalake/dataset/customer.sql -o customer.sql
curl -L https://s3-ap-southeast-1.amazonaws.com/dwbi-datalake/dataset/product.sql -o product.sql
curl -L https://s3-ap-southeast-1.amazonaws.com/dwbi-datalake/dataset/sales.sql -o sales.sql
curl -L https://s3-ap-southeast-1.amazonaws.com/dwbi-datalake/dataset/stocks.sql -o stocks.sql

mysql --host=127.0.0.1 --port=3306 --user root -p${db_password} -e "create database sales;"
mysql --host=127.0.0.1 --port=3306 --user root -p${db_password} sales < /root/mariadb/showroom.sql
mysql --host=127.0.0.1 --port=3306 --user root -p${db_password} sales < /root/mariadb/customer.sql
mysql --host=127.0.0.1 --port=3306 --user root -p${db_password} sales < /root/mariadb/product.sql
mysql --host=127.0.0.1 --port=3306 --user root -p${db_password} sales < /root/mariadb/sales.sql
mysql --host=127.0.0.1 --port=3306 --user root -p${db_password} sales < /root/mariadb/stocks.sql

mysql --host=127.0.0.1 --port=3306 --user root -p${db_password} -e "alter table showroom modify column id int auto_increment primary key;" sales
mysql --host=127.0.0.1 --port=3306 --user root -p${db_password} -e "alter table customer modify column id int auto_increment primary key;" sales
mysql --host=127.0.0.1 --port=3306 --user root -p${db_password} -e "alter table product modify column id int auto_increment primary key;" sales
mysql --host=127.0.0.1 --port=3306 --user root -p${db_password} -e "alter table stocks modify column id int auto_increment primary key;" sales


# Install PostgreSQL Client
sudo yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo yum -y install epel-release yum-utils
sudo yum-config-manager --enable pgdg14
sudo yum -y install postgresql14

# Spawn PostgreSQL Source Container
mkdir /root/postgres_src
cd /root/postgres_src
sudo tee /root/postgres_src/docker-compose.yml &>/dev/null <<EOF
version: "3.1"
services:
  postgres_src:
    image: postgres:latest
    ports:
      - 5432:5432
    environment:
      POSTGRES_PASSWORD: ${db_password}
    command:
      - "postgres"
      - "-c"
      - "wal_level=logical"
EOF

docker-compose up -d
echo "PGPASSWORD=${db_password}" >> ~/.bash_profile 
echo 'export PGPASSWORD' >> ~/.bash_profile
source ~/.bash_profile
# PostgreSQL Source Database
sleep 30;

psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "CREATE TABLE consultants(id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,first_name VARCHAR(50),last_name VARCHAR(50),email VARCHAR(50),rate NUMERIC(8,2),status VARCHAR(20),created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP);"
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "ALTER TABLE consultants REPLICA IDENTITY USING INDEX consultants_pkey;"
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "INSERT INTO consultants(first_name, last_name, email, rate, status) values ('John', 'Doe', 'john.doe@gmail.com', 3000.00, 'perm');"
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "INSERT INTO consultants(first_name, last_name, email, rate, status) values ('Tom', 'Hanks', 'tom.hanks@yahoo.com', 3500.75, 'contract');"
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "INSERT INTO consultants(first_name, last_name, email, rate, status) values ('Jane', 'Doe', 'jane.doe@moneybank.com', 3500.75, 'perm');"
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "INSERT INTO consultants(first_name, last_name, email, rate, status) values ('Duke', 'Johnson', 'duke@hello.com', 4500.25, 'contract');"
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "INSERT INTO consultants(first_name, last_name, email, rate, status) values ('Peter', 'Parker', 'peter@gmail.com', 4500.25, 'contract');"
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "INSERT INTO consultants(first_name, last_name, email, rate, status) values ('Rick', 'Nice', 'rick@gmail.com', 4900, 'contract');"
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "INSERT INTO consultants(first_name, last_name, email, rate, status) values ('Tommy', 'Hill', 'tommy@gmail.com', 4100, 'perm');"
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "INSERT INTO consultants(first_name, last_name, email, rate, status) values ('Jill', 'Stone', 'jill@gmail.com', 4250.50, 'contract');"
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "INSERT INTO consultants(first_name, last_name, email, rate, status) values ('Honey', 'Bee', 'honey@gmail.com', 3200, 'perm');"
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "INSERT INTO consultants(first_name, last_name, email, rate, status) values ('Bell', 'Doe', 'bell@gmail.com', 34000, 'contract');"


# Spawn PostgreSQL Target Container
mkdir /root/postgres_tgt
cd /root/postgres_tgt
sudo tee /root/postgres_tgt/docker-compose.yml &>/dev/null <<EOF
version: "3.1"
services:
  postgres_tgt:
    image: postgres:latest
    ports:
      - 5433:5432
    environment:
      POSTGRES_PASSWORD: ${db_password}
    command:
      - "postgres"
      - "-c"
      - "wal_level=logical"
EOF

docker-compose up -d
# PostgreSQL Target Database
sleep 30;

psql -U postgres -h 127.0.0.1 -p 5433 -d postgres -c "CREATE TABLE consultants(id INT PRIMARY KEY,first_name VARCHAR(50),last_name VARCHAR(50),email VARCHAR(50),rate NUMERIC(8,2),status VARCHAR(20),created_at TIMESTAMP,updated_at TIMESTAMP);"
psql -U postgres -h 127.0.0.1 -p 5433 -d postgres -c "CREATE TABLE consultants1(id INT PRIMARY KEY,first_name VARCHAR(50),last_name VARCHAR(50),email VARCHAR(50),rate NUMERIC(8,2),status VARCHAR(20),created_at TIMESTAMP,updated_at TIMESTAMP);"
psql -U postgres -h 127.0.0.1 -p 5433 -d postgres -c "CREATE TABLE product(id INT PRIMARY KEY,code VARCHAR(50),category VARCHAR(6),make VARCHAR(50),model VARCHAR(50),year VARCHAR(50),color VARCHAR(50),price INT,currency VARCHAR(50),update_date TIMESTAMP,create_date TIMESTAMP);"
psql -U postgres -h 127.0.0.1 -p 5433 -d postgres -c "CREATE TABLE customer(customerid INT PRIMARY KEY,namestyle VARCHAR(5),title VARCHAR(8),firstname VARCHAR(50),middlename VARCHAR(50),lastname VARCHAR(50),suffix VARCHAR(10),companyname VARCHAR(128),salesperson VARCHAR(256),emailaddress VARCHAR(50),phone VARCHAR(25),passwordhash VARCHAR(128),passwordsalt VARCHAR(10),rowguid VARCHAR(50),modifieddate TIMESTAMP);"
psql -U postgres -h 127.0.0.1 -p 5433 -d postgres -c "CREATE TABLE customer1(customerid INT PRIMARY KEY,namestyle VARCHAR(5),title VARCHAR(8),firstname VARCHAR(50),middlename VARCHAR(50),lastname VARCHAR(50),suffix VARCHAR(10),companyname VARCHAR(128),salesperson VARCHAR(256),emailaddress VARCHAR(50),phone VARCHAR(25),passwordhash VARCHAR(128),passwordsalt VARCHAR(10),rowguid VARCHAR(50),modifieddate TIMESTAMP);"


# Spawn Elasticsearch Container
mkdir /root/elk
cd /root/elk
sudo tee /root/elk/docker-compose.yml &>/dev/null <<EOF
version: "3"
services:
  elasticsearch:
    image: elasticsearch:7.13.1
    ports:
      - 9200:9200
    environment:
      - bootstrap.memory_lock=true
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms2g -Xmx2g"
      - ELASTIC_PASSWORD=${db_password}
      - xpack.security.enabled=true
    ulimits:
      memlock:
        soft: -1
        hard: -1
    networks: ['elk']
  kibana:
    image: kibana:7.13.1
    ports: ['5601:5601']
    environment:
      - ELASTICSEARCH_USERNAME=elastic
      - ELASTICSEARCH_PASSWORD=${db_password}
    networks: ['elk']
    links: ['elasticsearch']
    depends_on: ['elasticsearch']
networks:
  elk: {}
EOF

docker-compose up -d


# Install MongoDB Client
echo "[mongodb-org-4.4]" > /etc/yum.repos.d/mongodb-org-4.4.repo
echo "name=MongoDB Repository" >> /etc/yum.repos.d/mongodb-org-4.4.repo
echo 'baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/4.4/x86_64/' >> /etc/yum.repos.d/mongodb-org-4.4.repo
echo "gpgcheck=1" >> /etc/yum.repos.d/mongodb-org-4.4.repo
echo "enabled=1" >> /etc/yum.repos.d/mongodb-org-4.4.repo
echo "gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc" >> /etc/yum.repos.d/mongodb-org-4.4.repo
sudo yum -y install mongodb-org-shell-4.4.2
# Spawn MongoDB Container
mkdir /root/mongodb
cd /root/mongodb
sudo tee /root/mongodb/docker-compose.yml &>/dev/null <<EOF
version: "3.1"
services:
  mongo:
    image: mongo
    ports:
      - 27017:27017
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: ${db_password}
EOF

docker-compose up -d


# Install Redis
sudo yum -y install epel-release
sudo yum -y update
sudo yum -y install redis
sed -i -e "s|bind 127.0.0.1|# bind 127.0.0.1|" /etc/redis.conf
sed -i -e "s|# requirepass foobared|requirepass ${db_password}|" /etc/redis.conf
systemctl enable redis
systemctl restart redis


# Install MSSQL CLI Client
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
curl https://packages.microsoft.com/config/rhel/7/prod.repo > /etc/yum.repos.d/msprod.repo
sudo yum -y install libunwind
sudo yum -y install mssql-cli
# Spawn MSSQL Container
mkdir /root/mssql
cd /root/mssql
sudo tee /root/mssql/docker-compose.yml &>/dev/null <<EOF
version: "3.1"
services:
  mssql:
    image: mcr.microsoft.com/mssql/server:2019-latest
    container_name: mssql
    ports:
      - 1433:1433
    environment:
      ACCEPT_EULA: Y
      SA_PASSWORD: ${db_password}
      MSSQL_PID: Developer
      MSSQL_AGENT_ENABLED: "true"
EOF

docker-compose up -d
# MSSQL Source Database
sleep 60;
curl -L https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorksLT2019.bak -o AdventureWorksLT2019.bak
sudo docker cp AdventureWorksLT2019.bak mssql:/AdventureWorksLT2019.bak
mssql-cli -S localhost -U sa -P ${db_password} -Q "RESTORE DATABASE [AdventureWorks] FROM DISK='/AdventureWorksLT2019.bak' WITH MOVE 'AdventureWorksLT2012_Data' TO '/var/opt/mssql/data/AdventureWorks.mdf', MOVE 'AdventureWorksLT2012_Log' TO '/var/opt/mssql/data/AdventureWorks_log.ldf'"
mssql-cli -S localhost -U sa -P ${db_password} -Q "USE adventureworks; EXEC sp_changedbowner 'sa'; EXEC sys.sp_cdc_enable_db;"
mssql-cli -S localhost -U sa -P ${db_password} -d adventureworks -Q "EXEC sys.sp_cdc_enable_table @source_schema = 'saleslt', @source_name = 'customer', @role_name = NULL, @supports_net_changes = 0;"



# Oracle Objects Try Now
sqlplus "sys/${db_password}@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=10.0.1.100)(PORT=1521))(CONNECT_DATA=(SID=ORCLCDB)))" as sysdba @/root/oracle_src/oracle_src_objects.sql
sqlplus "sys/${db_password}@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=10.0.1.100)(PORT=1521))(CONNECT_DATA=(SID=ORCLCDB)))" as sysdba @/root/oracle_src/oracle_src_data.sql
sqlplus "sys/${db_password}@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=10.0.1.100)(PORT=1525))(CONNECT_DATA=(SID=ORCLCDB)))" as sysdba @/root/oracle_tgt/oracle_tgt_objects.sql

touch /root/done.out
