#!/bin/bash
set -xeo pipefail
exec > >(tee "/home/${USER}/azure_agent_setup.log") 2>&1

USER_HOME="/home/${USER}"
cd "$USER_HOME"
mkdir -p Downloads
cd Downloads
wget -nv https://vstsagentpackage.azureedge.net/agent/3.248.0/vsts-agent-linux-x64-3.248.0.tar.gz
cd .. && mkdir -p myagent && cd myagent
tar zxf "$USER_HOME/Downloads/vsts-agent-linux-x64-3.248.0.tar.gz"

runuser -l "${USER}" -c './myagent/config.sh --unattended --url "https://dev.azure.com/${ORG}" \
    --auth pat --token "${PAT}" --pool "${POOL}"'
sudo ./svc.sh install
sudo ./svc.sh start

sudo apt update
sudo apt install -y unzip
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
