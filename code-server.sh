#!/bin/bash
export VERSION=4.5.1
curl -fOL https://github.com/coder/code-server/releases/download/v$VERSION/code-server_$VERSION_amd64.deb
sudo dpkg -i code-server_$VERSION_amd64.deb
sudo systemctl enable --now code-server@$USER