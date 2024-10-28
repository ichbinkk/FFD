#!/bin/bash

apt install curl unzip

read -p "是否是要更新easytier? (yes/y/no/n,默认no): " input
input=${input:-no}
if [[ "$input" == "yes" || "$input" == "y" ]]; then
    wget -O /tmp/easytier.sh "https://raw.githubusercontent.com/EasyTier/EasyTier/main/script/install.sh" && bash /tmp/easytier.sh update
elif [[ "$input" == "no" || "$input" == "n" ]]; then
    wget -O /tmp/easytier.sh "https://raw.githubusercontent.com/EasyTier/EasyTier/main/script/install.sh" && bash /tmp/easytier.sh install
else
    echo "输入无效，请输入 'yes' 或 'no'。"
    exit 1
fi

# 询问用户是否要安装公共服务器
read -p "是否是要安装公共server? (yes/y/no/n,默认no): " input
input=${input:-no}
    
# 根据用户输入选择相应的 ExecStart 配置
if [[ "$input" == "yes" || "$input" == "y" ]]; then
    EXEC_START="easytier-core --network-name kkworld --network-secret 22022Wk* --relay-network-whitelist kkworld"
    ip=`curl -s ifconfig.me`
    echo "New peer address is:"
    echo "tcp://"$ip":11010"
elif [[ "$input" == "no" || "$input" == "n" ]]; then
    read -p "IP or domain of public server? (tw.821321.xyz): " domain
    domain=${domain:-tw.821321.xyz}
    read -p "IP in ipv4? (158.132.16.21): " ip4
    ip4=${ip4:-158.132.16.21}
    read -p "IP range to route? (10.0.0.0): " route
    route=${route:-158.132.117.0}
    EXEC_START="easytier-core --ipv4 "$ip4" --network-name kkworld --network-secret 22022Wk* --peers tcp://"$domain":11010 --disable-p2p -n "$route"/24"        
else
    echo "输入无效，请输入 'yes' 或 'no'。"
    exit 1
fi

# 定义目标文件路径
FILE_PATH="/etc/systemd/system/easytier@default.service"
# 写入新的内容到服务文件
sudo bash -c "cat > $FILE_PATH << EOF
[Unit]
Description=EasyTier Service
After=network.target syslog.target
Wants=network.target

[Service]
Type=simple
ExecStart=$EXEC_START

[Install]
WantedBy=multi-user.target
EOF
"

# 重新加载 systemd 配置
sudo systemctl daemon-reload    
sudo systemctl restart easytier@default.service    
echo "easytier@default.service已更新，并已重新加载 systemd 配置。"