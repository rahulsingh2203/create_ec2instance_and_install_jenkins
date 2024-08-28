# EC2 Instance Creation and Jenkins Installation

## Overview

This project demonstrates how to automate the creation of an Amazon EC2 instance and install Jenkins on it using a Bash script. Jenkins is a widely used open-source automation server that facilitates continuous integration and continuous delivery (CI/CD).

## Prerequisites

1. **AWS CLI**: Ensure that you have the AWS Command Line Interface (CLI) installed and configured with your AWS credentials.
2. **IAM Permissions**: Ensure your IAM user or role has the necessary permissions to create EC2 instances and manage security groups.
3. **SSH Key Pair**: You need an existing SSH key pair for connecting to your EC2 instance.
4. **Security Group**: Ensure that you have a security group configured to allow inbound traffic on port 22 (SSH) and port 8080 (Jenkins).

## Configuration

Before running the script, you need to configure the following variables in the script:

- `REGION`: AWS region where you want to launch the EC2 instance (e.g., `ap-south-1` for Mumbai).
- `INSTANCE_TYPE`: EC2 instance type (e.g., `t2.micro`).
- `AMI_ID`: AMI ID for the desired Ubuntu version (e.g., `ami-0b69ea66ff7391e80` for Ubuntu 20.04 LTS in Mumbai).
- `KEY_NAME`: Name of your SSH key pair.
- `SECURITY_GROUP`: ID or name of the security group that allows HTTP and SSH traffic.

## Script

The script `create_ec2_and_install_jenkins.sh` performs the following actions:

1. **Launches an EC2 instance** using the AWS CLI.
2. **Waits** until the instance is running.
3. **Retrieves the public IP address** of the newly launched instance.
4. **Connects to the instance via SSH** and installs Jenkins.
5. **Starts Jenkins** and makes it accessible on port 8080.

Here is the script:

```bash
#!/bin/bash

# Configuration
REGION="ap-south-1"  # AWS region Mumbai
INSTANCE_TYPE="t2.micro"  # Change this if you need a different instance type
AMI_ID="ami-0b69ea66ff7391e80"  # Ubuntu 20.04 LTS AMI ID in ap-south-1; update if needed
KEY_NAME="my-key-pair"  # Change this to your key pair name
SECURITY_GROUP="my-security-group"  # Change this to your security group ID or name

# Launch EC2 Instance
INSTANCE_ID=$(aws ec2 run-instances \
    --region "$REGION" \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-groups "$SECURITY_GROUP" \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Launching EC2 instance with ID: $INSTANCE_ID"

# Wait for the instance to be running
echo "Waiting for the instance to be running..."
aws ec2 wait instance-running \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID"

# Get the public IP address of the instance
PUBLIC_IP=$(aws ec2 describe-instances \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "Instance is running. Public IP: $PUBLIC_IP"

# SSH into the instance and install Jenkins
ssh -o StrictHostKeyChecking=no -i "${KEY_NAME}.pem" ubuntu@"$PUBLIC_IP" << EOF
    # Update package index
    sudo apt update -y

    # Install Java (Jenkins requirement)
    sudo apt install -y openjdk-11-jdk

    # Add Jenkins repository
    wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
    sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

    # Update package index again with Jenkins repository
    sudo apt update -y

    # Install Jenkins
    sudo apt install -y jenkins

    # Start Jenkins service
    sudo systemctl start jenkins
    sudo systemctl enable jenkins

    # Open Jenkins in a browser
    echo "Jenkins should be available at http://$PUBLIC_IP:8080"
EOF

echo "Jenkins installation script finished."
