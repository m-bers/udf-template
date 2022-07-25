#!/bin/bash

# UDF Console steps:
# In the sidebar, click Deployments, then click Create Deployment in the top right
# Set provider to UDF and give the deployment a name
# Open the new deployment, click "Cloud Accounts", then "Add AWS Cloud Account"
# Click Components, then Systems, then Add.
# Choose template Ubuntu 20.04 LTS Server
# Set to 4 vCPUs, 15GB RAM, 370GB Disk, then click Create
# Click start, and select n1-standard-4 as the deployment size
# SSH into the Ubuntu VM once started

# Set up AWS CLI
sudo apt-get update && sudo apt-get -y install unzip jq git curl
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install