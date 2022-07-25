#!/bin/bash
export VERSION=4.5.1
curl -fOL "https://github.com/coder/code-server/releases/download/v${VERSION}/code-server_${VERSION}_amd64.deb"
sudo dpkg -i "code-server_${VERSION}_amd64.deb"
sudo systemctl enable --now code-server@${USER}
sudo apt-get update && sudo apt-get -y install nginx

# Install NGINX proxy
sudo cat << 'EOF' > sudo tee /etc/nginx/sites-available/code-server
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
            '<link rel="stylesheet" type="text/css" href="/custom-fonts/css/fonts.css">
            </head>';
            sub_filter_once on;

            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_redirect off;
        }

        location /fonts {
            autoindex on;
            root /var/www/html;
        }
    }
EOF
sudo ln -s /etc/nginx/sites-available/code-server /etc/nginx/sites-enabled/code-server

# Install fonts
sudo mkdir -p /var/www/html/custom-fonts/fonts
sudo wget https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Regular.ttf -P /var/www/html/custom-fonts/fonts
sudo wget https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Bold.ttf -P /var/www/html/custom-fonts/fonts
sudo wget https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Italic.ttf -P /var/www/html/custom-fonts/fonts
sudo wget https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Bold%20Italic.ttf -P /var/www/html/custom-fonts/fonts
sudo mkdir -p /var/www/html/custom-fonts/css
sudo cat << 'EOF' > sudo tee /var/www/html/custom-fonts/css/fonts.css
    @font-face {
    font-family: "MesloLGS NF";
    src: url("/custom-fonts/fonts/MesloLGS%20NF%20Regular.ttf");
    font-weight: normal;
    font-style: normal;
    }
    @font-face {
        font-family: "MesloLGS NF";
        src: url("/custom-fonts/fonts/MesloLGS%20NF%20Bold.ttf");
        font-weight: bold;
        font-style: normal;
    }
    @font-face {
        font-family: "MesloLGS NF";
        src: url("/custom-fonts/fonts/MesloLGS%20NF%20Italic.ttf");
        font-weight: normal;
        font-style: italic;
    }
    @font-face {
        font-family: "MesloLGS NF";
        src: url("/custom-fonts/fonts/MesloLGS%20NF%20Bold%20Italic.ttf");
        font-weight: bold;
        font-style: italic;
    }
EOF

sudo systemctl restart nginx