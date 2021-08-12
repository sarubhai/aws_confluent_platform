#!/bin/bash
# Name: database_server.sh
# Owner: Saurav Mitra
# Description: Configure containerized database server for demo

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


# Build Oracle 11g Image (oracle/database:11.2.0.2-xe)
cd /root
sudo yum -y install git
git clone https://github.com/oracle/docker-images.git
cd /root/docker-images/OracleDatabase/SingleInstance/dockerfiles/11.2.0.2
curl https://ashnik-confluent-oracle-demo.s3-us-west-2.amazonaws.com/oracle-xe-11.2.0-1.0.x86_64.rpm.zip -o oracle-xe-11.2.0-1.0.x86_64.rpm.zip
cd /root/docker-images/OracleDatabase/SingleInstance/dockerfiles
./buildContainerImage.sh -x -v 11.2.0.2 -o "--memory=1g --memory-swap=2g"


# Spawn Oracle Source Container
mkdir /root/oracle_src
cd /root/oracle_src
sudo tee /root/oracle_src/docker-compose.yml &>/dev/null <<EOF
version: "3"
services:
  oracle_src:
    image: oracle/database:11.2.0.2-xe
    shm_size: 1gb
    ports:
      - "1521:1521"
    environment:
      - ORACLE_PWD=${db_password}
EOF

docker-compose up -d

# Spawn Oracle Target Container
mkdir /root/oracle_tgt
cd /root/oracle_tgt
sudo tee /root/oracle_tgt/docker-compose.yml &>/dev/null <<EOF
version: "3"
services:
  oracle_tgt:
    image: oracle/database:11.2.0.2-xe
    shm_size: 1gb
    ports:
      - "1525:1521"
    environment:
      - ORACLE_PWD=${db_password}
EOF

docker-compose up -d

# Initial Database Setup
# Oracle XE 11g Source
while [ "`docker inspect -f {{.State.Health.Status}} oracle_src_oracle_src_1`" != "healthy" ]; do
  sleep 60;
done;
# SYSDBA
sqlplus -s /nolog <<EOF >${db_password}
connect sys/${db_password}@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))(CONNECT_DATA=(SID=XE))) as sysdba
alter user hr account unlock identified by hr;
create user orcl_user identified by ${db_password};
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

# ORCL
sqlplus -s /nolog <<EOF >${db_password}
connect orcl_user/${db_password}@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))(CONNECT_DATA=(SID=XE)))
CREATE TABLE CONSULTANTS("ID" NUMBER(10) NOT NULL PRIMARY KEY,"FIRST_NAME" VARCHAR(50),"LAST_NAME" VARCHAR(50),"EMAIL" VARCHAR(50),"RATE" NUMBER(8,2),"STATUS" VARCHAR(20),"CREATED_AT" timestamp DEFAULT CURRENT_TIMESTAMP,"UPDATED_AT" timestamp NOT NULL);
CREATE SEQUENCE CONSULTANTS_SEQUENCE;
CREATE OR REPLACE TRIGGER TRG_CONSULTANTS_INS BEFORE INSERT ON CONSULTANTS FOR EACH ROW  BEGIN  SELECT CONSULTANTS_SEQUENCE.nextval INTO :new.ID FROM dual; END;
/
CREATE OR REPLACE TRIGGER TRG_CONSULTANTS_UPD BEFORE INSERT OR UPDATE ON CONSULTANTS REFERENCING NEW AS NEW_ROW FOR EACH ROW  BEGIN   SELECT SYSDATE INTO :NEW_ROW.UPDATED_AT FROM DUAL; END;
/
insert into CONSULTANTS(FIRST_NAME, LAST_NAME, EMAIL, RATE, STATUS) values ('John', 'Doe', 'john.doe@gmail.com', 3000.00, 'perm');
insert into CONSULTANTS(FIRST_NAME, LAST_NAME, EMAIL, RATE, STATUS) values ('Tom', 'Hanks', 'tom.hanks@yahoo.com', 3500.75, 'contract');
insert into CONSULTANTS(FIRST_NAME, LAST_NAME, EMAIL, RATE, STATUS) values ('Jane', 'Doe', 'jane.doe@moneybank.com', 3500.75, 'perm');
insert into CONSULTANTS(FIRST_NAME, LAST_NAME, EMAIL, RATE, STATUS) values ('Duke', 'Johnson', 'duke@hello.com', 4500.25, 'contract');
insert into CONSULTANTS(FIRST_NAME, LAST_NAME, EMAIL, RATE, STATUS) values ('Peter', 'Parker', 'peter@gmail.com', 4500.25, 'contract');
commit;
quit
EOF


# Oracle XE 11g Target
while [ "`docker inspect -f {{.State.Health.Status}} oracle_tgt_oracle_tgt_1`" != "healthy" ]; do
  sleep 60;
done;
# SYSDBA
sqlplus -s /nolog <<EOF >${db_password}
connect sys/${db_password}@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1525))(CONNECT_DATA=(SID=XE))) as sysdba
create user orcl_user identified by ${db_password};
grant DBA to orcl_user;
CREATE TABLE "ORCL_USER"."EMPLOYEES"("EMPLOYEE_ID" NUMBER(6,0),"FIRST_NAME" VARCHAR2(20),"LAST_NAME" VARCHAR2(25),"EMAIL" VARCHAR2(25),"PHONE_NUMBER" VARCHAR2(20),"HIRE_DATE" DATE,"JOB_ID" VARCHAR2(10),"SALARY" NUMBER(8,2),"COMMISSION_PCT" NUMBER(2,2),"MANAGER_ID" NUMBER(6,0),"DEPARTMENT_ID" NUMBER(4,0));
CREATE TABLE "ORCL_USER"."EMPLOYEES1"("EMPLOYEE_ID" NUMBER(6,0),"FIRST_NAME" VARCHAR2(20),"LAST_NAME" VARCHAR2(25),"EMAIL" VARCHAR2(25),"PHONE_NUMBER" VARCHAR2(20),"HIRE_DATE" DATE,"JOB_ID" VARCHAR2(10),"SALARY" NUMBER(8,2),"COMMISSION_PCT" NUMBER(2,2),"MANAGER_ID" NUMBER(6,0),"DEPARTMENT_ID" NUMBER(4,0));
CREATE TABLE "ORCL_USER"."CONSULTANTS"("ID" NUMBER(10) NOT NULL PRIMARY KEY,"FIRST_NAME" VARCHAR(50),"LAST_NAME" VARCHAR(50),"EMAIL" VARCHAR(50),"RATE" NUMBER(8,2),"STATUS" VARCHAR(20),"CREATED_AT" timestamp DEFAULT CURRENT_TIMESTAMP,"UPDATED_AT" timestamp NOT NULL);
CREATE TABLE "ORCL_USER"."CONSULTANTS1"("ID" NUMBER(10) NOT NULL PRIMARY KEY,"FIRST_NAME" VARCHAR(50),"LAST_NAME" VARCHAR(50),"EMAIL" VARCHAR(50),"RATE" NUMBER(8,2),"STATUS" VARCHAR(20),"CREATED_AT" timestamp DEFAULT CURRENT_TIMESTAMP,"UPDATED_AT" timestamp NOT NULL);
quit
EOF


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
sudo yum -y install postgresql
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

psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "CREATE TABLE consultants(id SERIAL NOT NULL PRIMARY KEY,first_name VARCHAR(50),last_name VARCHAR(50),email VARCHAR(50),rate NUMERIC(8,2),status VARCHAR(20),created_at timestamp without time zone default (now() at time zone 'utc') NOT NULL,updated_at timestamp without time zone default (now() at time zone 'utc') NOT NULL);"
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "insert into consultants(first_name, last_name, email, rate, status) values ('John', 'Doe', 'john.doe@gmail.com', 3000.00, 'perm');"
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "insert into consultants(first_name, last_name, email, rate, status) values ('Tom', 'Hanks', 'tom.hanks@yahoo.com', 3500.75, 'contract');"
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "insert into consultants(first_name, last_name, email, rate, status) values ('Jane', 'Doe', 'jane.doe@moneybank.com', 3500.75, 'perm');"
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "insert into consultants(first_name, last_name, email, rate, status) values ('Duke', 'Johnson', 'duke@hello.com', 4500.25, 'contract');"
psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "insert into consultants(first_name, last_name, email, rate, status) values ('Peter', 'Parker', 'peter@gmail.com', 4500.25, 'contract');"


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

psql -U postgres -h 127.0.0.1 -p 5433 -d postgres -c "CREATE TABLE consultants(id INTEGER NOT NULL PRIMARY KEY,first_name VARCHAR(50),last_name VARCHAR(50),email VARCHAR(50),rate NUMERIC(8,2),status VARCHAR(20),created_at timestamp without time zone NOT NULL,updated_at timestamp without time zone NOT NULL);"


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


# Spawn RabbitMQ Container
mkdir /root/rabbitmq
cd /root/rabbitmq
sudo tee /root/rabbitmq/docker-compose.yml &>/dev/null <<EOF
version: "3.1"
services:
  rabbitmq:
    image: rabbitmq:3.8-management
    container_name: "rabbitmq"
    ports:
      - 5672:5672
      - 15672:15672
    environment:
      RABBITMQ_DEFAULT_USER: rabbitmq
      RABBITMQ_DEFAULT_PASS: ${db_password}
EOF

docker-compose up -d
