# Practical Terraform Lab

This repo contains the solution code for the terraform labs.


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
  http://server-alb-878265324.ap-northeast-1.elb.amazonaws.com/parse/classes/Users
```

```bash
curl -X GET \
  -H "X-Parse-Application-Id: MY_APPLICATION_ID" \
  -H "Content-Type: application/json" \
  http://localhost:1337/parse/classes/Users



curl -X GET \
  -H "X-Parse-Application-Id: MY_APPLICATION_ID" \
  -H "Content-Type: application/json" \
  http://server-alb-878265324.ap-northeast-1.elb.amazonaws.com/parse/classes/Users
```

```bash
ssh -i ground-deployer.pem ec2-user@ec2-52-197-246-81.ap-northeast-1.compute.amazonaws.com

ssh -i ground-deployer.pem ec2-user@ec2-52-198-121-56.ap-northeast-1.compute.amazonaws.com
```