# Practical Terraform Lab

This repo contains the solution code for the terraform labs.

## Scenario

You are recently hired as a DevOps engineer in Acme Pte Ltd. At the moment, Acme is trying to prototype a simple mobile app with simple backend for persistence. After evaluation, they decided to use Parse Server (https://docs.parseplatform.org/parse-server/guide/) as the backend. Parse Server is a simple express server that provides APIs to integrate with MongoDB. It is simple to set up with Docker.

### Part 1

As the DevOps engineer, you now need to deploy Parse Server in AWS `ap-northeast-1` region. You have just recently learnt Terraform and hope to make use of Terraform to automate the provisioning of the infrastructure and deployment.

As the application is still in internal testing, Acme wants to save on infrastructure costs.

Requirements:
* `appId` and `masterKey` must be environment variables that can be passed in.
* Provision and deploy Parse Server using docker in AWS
* Use the AMI ID - `ami-08d175f1b493f205f` for the EC2 instance
* Instance size should be `t2.micro`
* The instance should only exposed port 22 (for ssh), 80, port 443 to the public
* The Parse Server's default port `1337` should be used, but hidden from the public. You can make use of Nginx to reverse proxy to the server.
* Terraform run output should return the instance's public DNS and public IP address.
* Use the SSH key `ground-deployer`

Once the instance is up, we should be able to create a user by running:

```bash
curl -X POST \
  -H "X-Parse-Application-Id: MY_APPLICATION_ID" \
  -H "Content-Type: application/json" \
  -d '{"age":37,"userName":"John Doe","email":"johndoe@example.com"}' \
  http://<server.public_dns>/parse/classes/Users
```

And verify that the user has been created:

```bash
curl -X GET \
  -H "X-Parse-Application-Id: MY_APPLICATION_ID" \
  -H "Content-Type: application/json" \
  http://<server.public_dns>/parse/classes/Users
```

Before getting into Terraform, you have manually tested the below script will result in a working Parse Server that meets part of the above requirements:

```bash
#!/bin/bash
sudo yum -y update
sudo yum -y install unzip

docker network create --attachable parse-server-default

echo "Running MongoDB Docker"
docker run --name database \
  --network parse-server-default \
  -d mongo

hostname=`curl http://169.254.169.254/latest/meta-data/public-hostname`

echo "Running Parse Server"
docker run --name web \
  --network parse-server-default \
  -v cloud-code-vol:/parse-server/cloud \
  -v config-vol:/parse-server/config \
  --env VIRTUAL_HOST=$hostname \
  -p 1337:1337 \
  -d parseplatform/parse-server \
  --appId APPLICATION_ID \
  --masterKey MASTER_KEY \
  --databaseURI mongodb://database/test

echo "Running the Nginx Reverse Proxy"
docker run -d --restart unless-stopped --name nginx-proxy \
  --network parse-server-default \
  -p 80:80 \
  -p 443:443 \
  --env VIRTUAL_PORT=1337 \
  --volume /var/run/docker.sock:/tmp/docker.sock:ro \
  jwilder/nginx-proxy
```

### Part 2

After several weeks of development work, Acme is now ready to beta test the mobile application. However, as the application collects user's specific data, Acme is concerned with the data security of the database. At the moment, the database is sitting in the same instance with the web tier.

Based on your knowledge, you recommend the following:
* Move the database to a new instance
* The database instance should not be publicly accessible, i.e. no public ingress in security groups
* Should only allow ingress to the DB port when it comes from the web instance

During your experiment, you have tested the following script will successfully provision a MongoDB instance:

```bash
#!/bin/bash
sudo yum -y update
sudo yum -y install unzip

echo "Running MongoDB Docker"
docker run --name database \
  -p 27017:27017 \
  -d mongo
```

And the following script can successfully connect the web instance to the MongoDB instance (assuming everything else is setup correctly):

```bash
#!/bin/bash
sudo yum -y update
sudo yum -y install unzip

docker network create --attachable parse-server-default

hostname=`curl http://169.254.169.254/latest/meta-data/public-hostname`

echo "Running Parse Server"
docker run --name web \
  --network parse-server-default \
  -v cloud-code-vol:/parse-server/cloud \
  -v config-vol:/parse-server/config \
  --env VIRTUAL_HOST=$hostname \
  -p 1337:1337 \
  -d parseplatform/parse-server \
  --appId APPLICATION_ID \
  --masterKey MASTER_KEY \
  --databaseURI mongodb://<db-private-ip>:27017/test

docker run -d --restart unless-stopped --name nginx-proxy \
  --network parse-server-default \
  -p 80:80 \
  -p 443:443 \
  --env VIRTUAL_PORT=1337 \
  --volume /var/run/docker.sock:/tmp/docker.sock:ro \
  jwilder/nginx-proxy
```

Make sure you replace the `<db-private-ip>` with the actual private IP of the database instance.

Tips:
* In the database security group, configure ingress to allow from the web's security group instead of IP address
* You will need database private IP address into the web instance's user_data script

### Part 3

The beta testing is completed and Acme is ready to launch the application. However, Acme is worry about the increase in the user requests which might bring down the backend server. On the other hand, Acme also do not want to spend too much provisioning a large EC2 instance only to find out there are no users.

You suggested the following:
* Set up an Auto Scaling Group on the web tier. At the moment, you are still in discussion with the rules and config for the auto scaling group. So just keep it minimal with desired, min and max capacity of 1 EC2 instance.
* Provision a load balancer which will balance the load between the instances created by the auto scaling group.
* Block the ingress access of the EC2 instances to the public, and only allow access from the load balancer.

Once the this is set up, we should be able to create a user by running:

```bash
curl -X POST \
  -H "X-Parse-Application-Id: MY_APPLICATION_ID" \
  -H "Content-Type: application/json" \
  -d '{"age":37,"userName":"John Doe","email":"johndoe@example.com"}' \
  http://<load_balancer.public_dns>/parse/classes/Users
```

And verify that the user has been created:

```bash
curl -X GET \
  -H "X-Parse-Application-Id: MY_APPLICATION_ID" \
  -H "Content-Type: application/json" \
  http://<load_balancer.public_dns>/parse/classes/Users
```

Tips:
* You will first have to create a launch template that has the EC2 instance config. This launch template will be used by the auto scaling group to provision new instances.
* You will have to use of the `base64encode` terraform function to encode the user_data in base64, which is the requirement of launch template.
* To connect ASG and ALB, you have to:
  * Create a target group and specify the target group in ASG
  * Create a ALB listener which forward port 80 requests to the target group


# Practical Terraform Lab

This lab is to set up a web server (using parse server which connects to MongoDB), and nginx reverse proxy to the server at port 1337, make the app server accessible at port 80.

## Part 1

Deploy parse server and mongo db in AWS Tokyo region. Use the AMI (`ami-08d175f1b493f205f`) which is designed to run docker images.

Requirements:
* `appId` and `masterKey` must be environment variables that can be passed in.
* The instance should only exposed port 80 and port 443 to the public.
* Instance size should be `t2.micro`
* The server port should be hidden, i.e. not exposed to the public directly. You may use Nginx to reverse proxy to the server.
* terraform run output should return the public DNS and public IP address.

## Part 2

Separate the mongoDB from the instance and make the instance not available to the public - only to the web server security group.

## Part 3

Provision multiple web servers with the same mongoDB instance, and a ALB and ASG to the web servers.

Requirements:
* Use Application Load Balancer
* 

Hint:
* Need to use launch template
* have to make use of the `base64encode` terraform function
* Create a target group

## Part 4

Shift the whole infrastructure to a VPC where the DB instance is inside the private subnet.

## Useful information

MongoDB port is 27017

Parse Server Docker: https://hub.docker.com/r/parseplatform/parse-server

## Useful commands

```bash
docker run --name my-mongo -d mongo
```

```bash
docker run --name my-parse-server \
  -v cloud-code-vol:/parse-server/cloud \
  -v config-vol:/parse-server/config \
  -p 1337:1337 \
  --link my-mongo:mongo \
  -d parseplatform/parse-server \
  --appId MY_APPLICATION_ID \
  --masterKey MY_MASTER_KEY \
  --databaseURI mongodb://mongo/test
```

```bash
curl -X POST \
  -H "X-Parse-Application-Id: MY_APPLICATION_ID" \
  -H "Content-Type: application/json" \
  -d '{"age":37,"userName":"John Doe","email":"johndoe@example.com"}' \
  http://localhost:1337/parse/classes/Users


curl -X POST \
  -H "X-Parse-Application-Id: MY_APPLICATION_ID" \
  -H "Content-Type: application/json" \
  -d '{"age":37,"userName":"John Doe","email":"johndoe@example.com"}' \
  http://server-alb-729816597.ap-northeast-1.elb.amazonaws.com/parse/classes/Users
```

```bash
curl -X GET \
  -H "X-Parse-Application-Id: MY_APPLICATION_ID" \
  -H "Content-Type: application/json" \
  http://localhost:1337/parse/classes/Users



curl -X GET \
  -H "X-Parse-Application-Id: MY_APPLICATION_ID" \
  -H "Content-Type: application/json" \
  http://server-alb-729816597.ap-northeast-1.elb.amazonaws.com/parse/classes/Users
```

```bash
ssh -i ground-deployer.pem ec2-user@ec2-52-197-246-81.ap-northeast-1.compute.amazonaws.com

ssh -i ground-deployer.pem ec2-user@ec2-52-198-121-56.ap-northeast-1.compute.amazonaws.com
```