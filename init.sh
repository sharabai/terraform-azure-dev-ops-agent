#!/bin/bash

mkdir -p Downloads
cd Downloads
wget https://vstsagentpackage.azureedge.net/agent/3.248.0/vsts-agent-linux-x64-3.248.0.tar.gz
cd .. && mkdir -p myagent && cd myagent
tar zxf ~/Downloads/vsts-agent-linux-x64-3.248.0.tar.gz

./config.sh --unattended --url "https://dev.azure.com/${ORG}" \
    --auth pat --token "${PAT}" --pool "${POOL}"
sudo ./svc.sh install
sudo ./svc.sh start

sudo apt update
sudo apt install unzip
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash