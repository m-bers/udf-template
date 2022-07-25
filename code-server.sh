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

# Get latest AWS credentials from UDI API
mkdir -p ~/.aws
printf "[default]\naws_access_key_id=" > ~/.aws/credentials
curl -s 10.1.1.1/cloudAccounts | jq '.cloudAccounts[0]' | jq -r ' .apiKey' >> ~/.aws/credentials
printf "aws_secret_access_key=" >> ~/.aws/credentials
curl -s 10.1.1.1/cloudAccounts | jq '.cloudAccounts[0]' | jq -r ' .apiSecret' >> ~/.aws/credentials
printf "[default]\nregion=us-west-2" > ~/.aws/config

# Install AWS CLI
sudo apt-get update && sudo apt-get -y install unzip jq git curl
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install code-server
export VERSION=4.4.0
curl -fOL "https://github.com/coder/code-server/releases/download/v${VERSION}/code-server_${VERSION}_amd64.deb"
sudo dpkg -i "code-server_${VERSION}_amd64.deb"
sudo systemctl enable --now code-server@${USER}

mkdir -p ~/.config/code-server
cat << 'EOF' > ~/.config/code-server/config.yaml
bind-addr: 127.0.0.1:8080
auth: none
cert: false
EOF

mkdir -p ~/.local/share/code-server/User
cat << 'EOF' > ~/.local/share/code-server/User/settings.json
{
    "workbench.colorTheme": "GitHub Dark Default",
    "terminal.integrated.fontFamily": "MesloLGS NF",
    "security.workspace.trust.enabled": false,
    "workbench.editorAssociations": {
        "*.md": "vscode.markdown.preview.editor"
    },
    "explorer.sortOrder": "type",
    "terminal.integrated.defaultProfile.linux": "zsh"
}
EOF

code-server --install-extension GitHub.github-vscode-theme

sudo systemctl restart --now code-server@${USER}

sudo apt-get update && sudo apt-get -y install nginx libnginx-mod-http-subs-filter zsh

# Install NGINX proxy
sudo cat << 'EOF' | sudo tee /etc/nginx/sites-available/code-server
server {
    listen 8081;

    location / {
        proxy_pass http://localhost:8080;

        proxy_set_header Accept-Encoding "";
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_set_header X-NginX-Proxy true;

        sub_filter
        '</head>'
        '<link rel="stylesheet" type="text/css" href="/code-server/css/fonts.css">
        </head>';
        sub_filter_once on;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_redirect off;
    }

    location /code-server {
        autoindex on;
        root /var/www/html;
    }

    location /_static/src/browser/media {
        autoindex on;
        root /var/www/html/code-server;
    }
}
EOF
sudo ln -s /etc/nginx/sites-available/code-server /etc/nginx/sites-enabled/code-server

# Install icons
sudo mkdir -p /var/www/html/code-server/_static/src/browser/media
sudo wget https://github.com/m-bers/udf-template/raw/main/vscode/code-192.png -P /var/www/html/code-server/_static/src/browser/media
sudo wget https://github.com/m-bers/udf-template/raw/main/vscode/code-512.png -P /var/www/html/code-server/_static/src/browser/media
sudo wget https://raw.githubusercontent.com/m-bers/udf-template/main/vscode/favicon-dark-support.svg -P /var/www/html/code-server/_static/src/browser/media
sudo wget https://raw.githubusercontent.com/m-bers/udf-template/main/vscode/favicon.ico -P /var/www/html/code-server/_static/src/browser/media

# Install fonts
sudo mkdir -p /var/www/html/code-server/fonts
sudo wget https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Regular.ttf -P /var/www/html/code-server/fonts
sudo wget https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Bold.ttf -P /var/www/html/code-server/fonts
sudo wget https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Italic.ttf -P /var/www/html/code-server/fonts
sudo wget https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Bold%20Italic.ttf -P /var/www/html/code-server/fonts
sudo mkdir -p /var/www/html/code-server/css

sudo cat << 'EOF' | sudo tee /var/www/html/code-server/css/fonts.css
@font-face {
font-family: "MesloLGS NF";
src: url("/code-server/fonts/MesloLGS%20NF%20Regular.ttf");
font-weight: normal;
font-style: normal;
}
@font-face {
    font-family: "MesloLGS NF";
    src: url("/code-server/fonts/MesloLGS%20NF%20Bold.ttf");
    font-weight: bold;
    font-style: normal;
}
@font-face {
    font-family: "MesloLGS NF";
    src: url("/code-server/fonts/MesloLGS%20NF%20Italic.ttf");
    font-weight: normal;
    font-style: italic;
}
@font-face {
    font-family: "MesloLGS NF";
    src: url("/code-server/fonts/MesloLGS%20NF%20Bold%20Italic.ttf");
    font-weight: bold;
    font-style: italic;
}
EOF

sudo systemctl restart nginx
wget https://raw.githubusercontent.com/m-bers/udf-template/main/.p10k.zsh -P ~
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k

cat << EOF > ~/.zshrc
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF