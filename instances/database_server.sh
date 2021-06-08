#!/bin/bash
# Name: database_server.sh
# Owner: Saurav Mitra
# Description: Configure containerized database server for demo

# Install Docker, Docker-compose
sudo yum -y install yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
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

echo 'ORACLE_HOME=/usr/lib/oracle/21/client64' >> ~/.bash_profile 
echo 'PATH=$ORACLE_HOME/bin:$PATH' >> ~/.bash_profile
echo 'LD_LIBRARY_PATH=$ORACLE_HOME/lib' >> ~/.bash_profile
echo 'export ORACLE_HOME' >> ~/.bash_profile
echo 'export LD_LIBRARY_PATH' >> ~/.bash_profile
echo 'export PATH' >> ~/.bash_profile
source ~/.bash_profile


# Build Oracle 11g Image (oracle/database:11.2.0.2-xe)
cd /root/docker-images/OracleDatabase/SingleInstance/dockerfiles/11.2.0.2
curl https://ashnik-confluent-oracle-demo.s3-us-west-2.amazonaws.com/oracle-xe-11.2.0-1.0.x86_64.rpm.zip -o oracle-xe-11.2.0-1.0.x86_64.rpm.zip
cd /root/docker-images/OracleDatabase/SingleInstance/dockerfiles
./buildContainerImage.sh -x -v 11.2.0.2 -o "--memory=1g --memory-swap=2g"


# Spawn Oracle Source Container
cd /root
mkdir oracle_src
cd /root/oracle_src
echo 'version: "3"' > docker-compose.yml
echo 'services:' >> docker-compose.yml
echo '    oracle_src:' >> docker-compose.yml
echo '        image: oracle/database:11.2.0.2-xe' >> docker-compose.yml
echo '        shm_size: 1gb' >> docker-compose.yml
echo '        ports:' >> docker-compose.yml
echo '            - "1521:1521"' >> docker-compose.yml
echo '        environment:' >> docker-compose.yml
echo "            - ORACLE_PWD=${oracle_password}" >> docker-compose.yml
docker-compose up -d

# Spawn Oracle Target Container
cd /root
mkdir oracle_tgt
cd /root/oracle_tgt
echo 'version: "3"' > docker-compose.yml
echo 'services:' >> docker-compose.yml
echo '    oracle_tgt:' >> docker-compose.yml
echo '        image: oracle/database:11.2.0.2-xe' >> docker-compose.yml
echo '        shm_size: 1gb' >> docker-compose.yml
echo '        ports:' >> docker-compose.yml
echo '            - "1525:1521"' >> docker-compose.yml
echo '        environment:' >> docker-compose.yml
echo "            - ORACLE_PWD=${oracle_password}" >> docker-compose.yml
docker-compose up -d


# Initial Database Setup
# Oracle XE 11g Source
until [ "`docker inspect -f {{.State.Health.Status}} oracle_src_oracle_src_1`"=="healthy" ]; do
    sleep 60;
done;

sqlplus -s /nolog <<EOF >${oracle_password}
connect sys/${oracle_password}@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))(CONNECT_DATA=(SID=XE))) as sysdba
alter user hr account unlock identified by hr;
create user orcl_user identified by ${oracle_password};
grant DBA to orcl_user;
create table orcl_user.EMPLOYEES as select * from hr.EMPLOYEES;
create table orcl_user.DEPARTMENTS as select * from hr.DEPARTMENTS;
create table orcl_user.JOBS as select * from hr.JOBS;
create table orcl_user.JOB_HISTORY as select * from hr.JOB_HISTORY;
create table orcl_user.COUNTRIES as select * from hr.COUNTRIES;
create table orcl_user.REGIONS as select * from hr.REGIONS;
create table orcl_user.LOCATIONS as select * from hr.LOCATIONS;
alter database ADD SUPPLEMENTAL LOG DATA;
alter database ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
quit
EOF

# Oracle XE 11g Target
until [ "`docker inspect -f {{.State.Health.Status}} oracle_tgt_oracle_tgt_1`"=="healthy" ]; do
    sleep 60;
done;

sqlplus -s /nolog <<EOF >${oracle_password}
connect sys/${oracle_password}@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1525))(CONNECT_DATA=(SID=XE))) as sysdba
create user orcl_user identified by ${oracle_password};
grant DBA to orcl_user;
quit
EOF


# Install MySQL Client
sudo yum -y install mysql
# Spawn MySQL/MaraiDB Container
docker run --name oltp_mysql -d -p 3306:3306 -e MYSQL_ROOT_HOST='%' -e MYSQL_ROOT_PASSWORD=${oracle_password} mariadb:latest --log-bin --binlog-format=ROW
# MySQL Source Database
mkdir /root/sqlfiles
cd /root/sqlfiles
curl -L https://s3-ap-southeast-1.amazonaws.com/dwbi-datalake/dataset/showroom.sql -o showroom.sql
curl -L https://s3-ap-southeast-1.amazonaws.com/dwbi-datalake/dataset/customer.sql -o customer.sql
curl -L https://s3-ap-southeast-1.amazonaws.com/dwbi-datalake/dataset/product.sql -o product.sql
curl -L https://s3-ap-southeast-1.amazonaws.com/dwbi-datalake/dataset/sales.sql -o sales.sql
curl -L https://s3-ap-southeast-1.amazonaws.com/dwbi-datalake/dataset/stocks.sql -o stocks.sql

mysql --host=127.0.0.1 --port=3306 --user root -p${oracle_password} -e "create database sales;"
mysql --host=127.0.0.1 --port=3306 --user root -p${oracle_password} sales < /root/sqlfiles/showroom.sql
mysql --host=127.0.0.1 --port=3306 --user root -p${oracle_password} sales < /root/sqlfiles/customer.sql
mysql --host=127.0.0.1 --port=3306 --user root -p${oracle_password} sales < /root/sqlfiles/product.sql
mysql --host=127.0.0.1 --port=3306 --user root -p${oracle_password} sales < /root/sqlfiles/sales.sql
mysql --host=127.0.0.1 --port=3306 --user root -p${oracle_password} sales < /root/sqlfiles/stocks.sql

mysql --host=127.0.0.1 --port=3306 --user root -p${oracle_password} -e "alter table showroom modify column id int auto_increment primary key;" sales
mysql --host=127.0.0.1 --port=3306 --user root -p${oracle_password} -e "alter table customer modify column id int auto_increment primary key;" sales
mysql --host=127.0.0.1 --port=3306 --user root -p${oracle_password} -e "alter table product modify column id int auto_increment primary key;" sales
mysql --host=127.0.0.1 --port=3306 --user root -p${oracle_password} -e "alter table stocks modify column id int auto_increment primary key;" sales


# Install PostgreSQL Client
sudo yum -y install postgresql
# Spawn PostgreSQL Container
docker run --name oltp_postgres -d -p 5432:5432 -e MYSQL_ROOT_HOST='%' -e POSTGRES_PASSWORD=${oracle_password} postgres:latest
# PostgreSQL Source Database
echo "PGPASSWORD=${oracle_password}" >> ~/.bash_profile 
echo 'export PGPASSWORD' >> ~/.bash_profile
source ~/.bash_profile
psql -h 127.0.0.1 -p 5432 -U postgres


# Spawn Elasticsearch & Kibana Container
mkdir /root/elk
cd /root/elk
echo 'version: "3"' > docker-compose.yml
echo 'services:' >> docker-compose.yml
echo '  elasticsearch:' >> docker-compose.yml
echo '    image: elasticsearch:7.13.1' >> docker-compose.yml
echo '    environment:' >> docker-compose.yml
echo '      - bootstrap.memory_lock=true' >> docker-compose.yml
echo '      - discovery.type=single-node' >> docker-compose.yml
echo '      - "ES_JAVA_OPTS=-Xms2g -Xmx2g"' >> docker-compose.yml
echo "      - ELASTIC_PASSWORD=${oracle_password}" >> docker-compose.yml
echo '      - xpack.security.enabled=true' >> docker-compose.yml
echo '    ulimits:' >> docker-compose.yml
echo '      memlock:' >> docker-compose.yml
echo '        soft: -1' >> docker-compose.yml
echo '        hard: -1' >> docker-compose.yml
echo '    ports:' >> docker-compose.yml
echo '      - 9200:9200' >> docker-compose.yml
echo "    networks: ['elk']" >> docker-compose.yml
echo '  kibana:' >> docker-compose.yml
echo '    image: kibana:7.13.1' >> docker-compose.yml
echo '    environment:' >> docker-compose.yml
echo '      - ELASTICSEARCH_USERNAME=elastic' >> docker-compose.yml
echo "      - ELASTICSEARCH_PASSWORD=${oracle_password}" >> docker-compose.yml
echo "    ports: ['5601:5601']" >> docker-compose.yml
echo "    networks: ['elk']" >> docker-compose.yml
echo "    links: ['elasticsearch']" >> docker-compose.yml
echo "    depends_on: ['elasticsearch']" >> docker-compose.yml
echo 'networks:' >> docker-compose.yml
echo '  elk: {}' >> docker-compose.yml

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
echo "version: '3.1'" > docker-compose.yml
echo 'services:' >> docker-compose.yml
echo '  mongo:' >> docker-compose.yml
echo '    image: mongo' >> docker-compose.yml
echo '    environment:' >> docker-compose.yml
echo '      MONGO_INITDB_ROOT_USERNAME: root' >> docker-compose.yml
echo "      MONGO_INITDB_ROOT_PASSWORD: ${oracle_password}" >> docker-compose.yml
echo '    ports:' >> docker-compose.yml
echo '      - 27017:27017' >> docker-compose.yml

docker-compose up -d
