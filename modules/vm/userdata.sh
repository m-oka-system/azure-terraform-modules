#!/bin/bash

# Common Variables
USER_NAME="azureuser"

# Install MySQL client
sudo apt-get -y update && sudo apt-get install -y mysql-client-core-8.0

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install docker
sudo snap install docker
sudo addgroup docker
sudo adduser $USER_NAME docker

sudo reboot
