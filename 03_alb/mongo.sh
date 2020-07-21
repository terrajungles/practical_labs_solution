#!/bin/bash
sudo yum -y update
sudo yum -y install unzip

echo "Running MongoDB Docker"
docker run --name database \
  -p ${db_port}:${db_port} \
  -d mongo