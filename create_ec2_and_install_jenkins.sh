#####################################################################################################
# Author: Rahul Singh
# Date: 28-08-24
# Version: 1.0.1
#####################################################################################################


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
