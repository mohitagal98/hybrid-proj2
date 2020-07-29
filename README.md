# Cloud Automation using Terraform -II
## Introduction

This article's purpose is as same as we saw in my previous article i.e. how Terraform can be used to create complete automated infrastructure. But in this article I am going to show the use of EFS(Elastic File System) instead of EBS(Elastic Bloack Store) which I used in my last article.

Please read my previous article on [cloud automation](https://www.linkedin.com/pulse/cloud-automation-terraform-mohit-agarwal/) before going ahead, as in this article I had explained each and every steps on how to setup the complete infrastructure and why we are doing this.

### What is EFS?

Amazon EFS provides a simple, scalable, fully managed elastic NFS file system for use with AWS Cloud services and on-premises resources. It is built to scale on demand to petabytes without disrupting applications, growing and shrinking automatically as you add and remove files, eliminating the need to provision and manage capacity to accommodate growth.

### Wondering why EFS in place of EBS?

The main differences between EBS and EFS is that EBS is only accessible from a single EC2 instance in your particular AWS region, while EFS allows you to mount the file system across multiple regions and instances.

## Purpose of this project:

1. To create the key and security group which allow the external user to use our website.

2. To launch EC2 instance.

3. In this EC2 instance need to use the key and security group which we have created in step first.

4. To create Amazon EFS and mount it with EC2 instance.

5. To copy the github repo code into the folder from where the webserver is accessing the pages.

6. To create S3 bucket, and copy/deploy the images into the s3 bucket and change the permission to public readable.

7. And at last, to create a Cloudfront using s3 bucket(which contains images) and use the Cloudfront URL to update the code in our webpages.

## Implementation

Here the code is almost same as what I have done in the previous article except that, here we are needed to use one service EFS and hence let's start with creating EFS and how to mount it to EC2.

### Create security group for NFS first:
```
# Creating security group for EFS

resource "aws_security_group" "efs-sg" {
depends_on=[
	aws_security_group.SecGroup
]
  name        = "efs-mnt"
  description = "Allows NFS traffic from instances within the VPC."
  vpc_id      = "vpc-e7e4f98f"


  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"

    cidr_blocks = ["172.31.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "allow_nfs_ec2"
  }
}
```

Here, this security group allows instances from the same VPC to use this EFS server i.e. allowing ingress rule for port 2049.

### Creating EFS server:

```
#EFS creation

resource "aws_efs_file_system" "efs_server" {
depends_on=[
	aws_security_group.efs-sg
]
	creation_token = "EFS Shared Data"
	encrypted = "true"
	tags = {
		Name = "EFS Shared Data" 
	}
}
```
### Mounting EFS:
```
#To mount EFS

resource "aws_efs_mount_target" "efs" {
	file_system_id = "${aws_efs_file_system.efs_server.id}"
	subnet_id = "subnet-e2f4ce8a"
	security_groups = [
		"${aws_security_group.efs-sg.id}"
	]
}
```
This resource Provides an Elastic File System (EFS) mount target. Moreover I have assigned previously created security group to it.

### Finally, creating an EC2 instance and mounting it to EFS:
The following code is creating an EC2 instance and template_file is reading the command.tpl file in which all the bash commands are written and rendering the data to EC2.

```
#Reads the file at the given path

data "template_file" "commands" {
  template = "${file("commands.tpl")}"
  vars = {
    efs_id = "${aws_efs_file_system.efs_server.id}"
  }
}

#Instance creation

resource "aws_instance" "ins1"{
depends_on=[
	aws_efs_mount_target.efs
]
	ami = "ami-005956c5f0f757d37"
	instance_type = "t2.micro"
	key_name = "webkey1"
	user_data = "${data.template_file.commands.rendered}"
	security_groups = [ "SecurityGroup1" ]
	tags = {
		name = "linuxos"
	}
}
```
### commands.tpl file:
```
#!/bin/bash
sudo su - root


#installing and starting docker service
yum install docker -y
service docker start
chkconfig docker on


#downloading docker-compose
curl -L https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose


# Installing AWS EFS Utilities
yum install amazon-efs-utils -y


mkdir /storage


#Mounting EFS
mount -t efs "${efs_id}":/ /storage


#Editing fstab so that EFS loads automatically on reboot
echo "${efs_id}":/ /storage efs defaults,_netdev 0 0 >> /etc/fstab

mkdir /storage/sqlstorage
mkdir /storage/phpstorage
rm -rf /storage/phpstorage/*


# Cloning git repo into storage
yum install git -y
git clone https://github.com/mohitagal98/hybrid-proj1.git
cp -rf hybrid-proj1/* /storage/phpstorage
cp -f hybrid-proj1/docker-compose.yml /root/


#Launching environment using docker-compose

docker-compose up
```
Now, we have created NFS and after completing all those steps which we did in my [previous article](https://www.linkedin.com/pulse/cloud-automation-terraform-mohit-agarwal/) also. Now, we are ready to build the infrastructure.

To see my terraform file, click [here](https://github.com/mohitagal98/hybrid-proj2/blob/master/terrafile.tf).
To see my command.tpl file, click [here](https://github.com/mohitagal98/hybrid-proj2/blob/master/commands.tpl).

So, finally everything is done and we are remained with two magic commands only:

```
terraform init
terraform apply -auto-approve
```
This will finally create the complete infrastructure in one go. 

![01](https://raw.githubusercontent.com/mohitagal98/hybrid-proj2/master/images/apply.JPG)

## EFS:
![02](https://raw.githubusercontent.com/mohitagal98/hybrid-proj2/master/images/efs.JPG)

## S3 BUCKET:
![03](https://raw.githubusercontent.com/mohitagal98/hybrid-proj2/master/images/s3%20bucket.JPG)

## CLOUD FRONT:
![04](https://raw.githubusercontent.com/mohitagal98/hybrid-proj2/master/images/cloud%20front.JPG)

## EDITING PHP FILES:
![05](https://raw.githubusercontent.com/mohitagal98/hybrid-proj2/master/images/indexfile.png)

## RESULT:
![06](https://raw.githubusercontent.com/mohitagal98/hybrid-proj2/master/images/page.JPG)
