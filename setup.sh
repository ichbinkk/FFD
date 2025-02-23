#!/bin/bash

# 功能1: 安装x-ui，开启bbr
function xui {
    apt install curl socat
    echo "Start install x-ui"
    # bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh)
    # wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
    bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/x-ui-yg/main/install.sh)
}

# 功能2: frps and frpc
function frp {
    read -p "Do you want to install frp server? (yes/y/no/n,,默认no): " input
    input=${input:-no}
    
    if [[ "$input" == "yes" || "$input" == "y" ]]; then
        echo "Start install frp server"
        wget --no-check-certificate https://raw.githubusercontent.com/clangcn/onekey-install-shell/master/frps/install-frps.sh -O ./install-frps.sh
        chmod 700 ./install-frps.sh
        ./install-frps.sh install
    elif [[ "$input" == "no" || "$input" == "n" ]]; then
        echo "Start install frp client"
        # 检查目标目录是否存在，如果不存在则创建
        if [[ ! -d "/etc/ss" ]]; then
            sudo mkdir -p "/etc/ss"
        fi
        
        wget -P /etc/ss -N --no-check-certificate https://github.com/ichbinkk/FFD/releases/download/v1.0/frpc
        chmod +x /etc/ss/frpc
        
        #step1 创建frpc.ini
        FILE_PATH="/etc/ss/frpc.ini"
        
        # 写入新的内容到服务文件
        sudo bash -c "cat > $FILE_PATH << EOF
[common]
server_addr = cloud.821321.xyz
server_port = 5443
token = dls5jB6naABf5NU3

[hz-ssh]
type = tcp
local_ip = 127.0.0.1
local_port = 32182
remote_port = 1522
EOF
"
        
        nano "$FILE_PATH"
        
        # 确认文件已创建并显示内容
        if [[ -s "$FILE_PATH" ]]; then
            echo "frpc.ini 文件已保存到 $FILE_PATH"
            echo "文件内容如下："
            cat "$FILE_PATH"
        else
            echo "$FILE_PATH创建失败。"
        fi
        
        #step2 创建fprc.service
        FILE_PATH="/etc/systemd/system/frpc.service"        
        
        # 写入新的内容到服务文件
        sudo bash -c "cat > $FILE_PATH << EOF
[Unit]
Description=Frpc Service
After=network.target syslog.target
Wants=network.target

[Service]
Type=simple
ExecStartPre=/bin/sleep 10
ExecStart=/etc/ss/frpc -c /etc/ss/frpc.ini

[Install]
WantedBy=multi-user.target
EOF
"
        
        sudo systemctl daemon-reload
        sudo systemctl enable frpc.service
        sudo systemctl restart frpc.service
        sudo systemctl status frpc.service    
    else
        echo "输入无效，请输入 'yes' 或 'no'。"
        exit 1
    fi

    # 检查是否存在此任务
    crontab -l | grep -q 'systemctl restart frpc.service &> /dev/null'
    if [ $? -ne 0 ]; then
      # 如果不存在，则添加任务
      (crontab -l; echo '0 */2 * * * systemctl restart frpc.service &> /dev/null') | crontab -
      echo "0 */2 * * * systemctl restart frpc.service 任务已添加到 root 的 crontab 中。"
    else
      echo "systemctl restart frpc.service 任务已存在于 root 的 crontab 中。"
    fi
}

# 功能3: easytier
function easytier {
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
        EXEC_START="/opt/easytier/easytier-core --ipv4 158.132.16.1 --network-name kkworld --network-secret 22022Wk* --relay-network-whitelist kkworld --vpn-portal wg://0.0.0.0:11013/10.14.14.0/24"
        ip=`curl -s ifconfig.me`
        echo "New peer address is:"
        echo "tcp://"$ip":11010"
    elif [[ "$input" == "no" || "$input" == "n" ]]; then
      	read -p "IP or domain of public server? (cloud.821321.xyz): " domain
      	domain=${domain:-cloud.821321.xyz}
        read -p "IP in ipv4? (158.132.16.2): " ip4
      	ip4=${ip4:-158.132.16.2}
        read -p "IP range to route? (10.0.0.0): " route
      	route=${route:-10.0.0.0}
        EXEC_START="/opt/easytier/easytier-core --ipv4 "$ip4" --network-name kkworld --network-secret 22022Wk* --peers tcp://"$domain":11010 --disable-p2p -n "$route"/24"        
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
ExecStartPre=/bin/sleep 10
ExecStart=$EXEC_START

[Install]
WantedBy=multi-user.target
EOF
"
    
    # 重新加载 systemd 配置
    sudo systemctl daemon-reload    
    sudo systemctl restart easytier@default.service    
    echo "easytier@default.service已更新，并已重新加载 systemd 配置。"    
    systemctl status easytier@default.service

    # 检查是否存在此任务
    crontab -l | grep -q 'systemctl restart easytier@default.service &> /dev/null'
    if [ $? -ne 0 ]; then
      # 如果不存在，则添加任务
      (crontab -l; echo '0 1 * * * systemctl restart easytier@default.service &> /dev/null') | crontab -
      echo "0 1 * * * systemctl restart easytier@default.service 任务已添加到 root 的 crontab 中。"
    else
      echo "systemctl restart easytier@default.service 任务已存在于 root 的 crontab 中。"
    fi
}

# 功能4: derper
function derper {
    echo "Start install derper"
    # Prompt for email with a default value
    read -p "Enter your email [ichbinwk@gmail.com]: " email
    email=${email:-ichbinwk@gmail.com}
    
    # Prompt for domain
    read -p "Enter your domain [cloud.821321.xyz]: " domain
    domain=${domain:-cloud.821321.xyz}
    
    # Step 1: Install acme.sh
    curl https://get.acme.sh | sh
    
    # Step 2: Register an account
    ~/.acme.sh/acme.sh --register-account -m "$email"
    
    # Step 3: Issue a certificate
    ~/.acme.sh/acme.sh --issue -d "$domain" --standalone
    
    # Step 4: Install the certificate
    ~/.acme.sh/acme.sh --installcert -d "$domain" \
      --key-file /root/.acme.sh/"$domain"_ecc/"$domain".key \
      --fullchain-file /root/.acme.sh/"$domain"_ecc/"$domain".crt
    
    # Step 5: Run the Docker container
    apt install docker.io
    
    docker stop derper
    docker rm derper
    
    docker run --restart always \
      --name derper -p 443:443 -p 3478:3478/udp \
      -v /root/.acme.sh/"$domain"_ecc/:/app/certs \
      -e DERP_CERT_MODE=manual \
      -e DERP_ADDR=:443 \
      -e DERP_DOMAIN="$domain" \
      -d ghcr.io/yangchuansheng/derper:latest
      
    # 检查是否存在此任务
    crontab -l | grep -q 'docker restart derper &> /dev/null'
    if [ $? -ne 0 ]; then
      # 如果不存在，则添加任务
      (crontab -l; echo '0 */6 * * * docker restart derper &> /dev/null') | crontab -
      echo "0 */6 * * * docker restart derper 任务已添加到 root 的 crontab 中。"
    else
      echo "docker restart derper 任务已存在于 root 的 crontab 中。"
    fi
}

# 功能5: 显示系统的内存使用情况
function show_memory_usage {
    echo "系统内存使用情况："
    free -h
}

# 显示主界面菜单
function show_menu {
    echo -e "\033[32m**************************************\033[0m"
    echo -e "\033[32mAutomatic script to install\033[0m"
    echo -e "\033[34m30/8/2024\033[0m"
    echo -e "\033[32m**************************************\033[0m"
    echo "请选择一个功能："
    echo "1) Install x-ui and open bbr"
    echo "2) Install frps or frpc"
    echo "3) Install easytier"
    echo "4) Install derper"
    echo "5) show RAM usage"
    echo "0) exit"
}

# 主循环，显示主菜单并处理用户选择
while true; do
    show_menu
    read -p "请输入您的选择 (0-5): " choice

    case $choice in
        1)
            xui
            ;;
        2)
            frp
            ;;
        3)
            easytier
            ;;
        4)
            derper
            ;;
        5)
            show_memory_usage
            ;;
        0)
            echo "退出脚本。"
            break
            ;;
        *)
            echo "无效的选择，请输入 0-5 之间的数字。"
            ;;
    esac

    echo "按任意键返回主菜单..."
    read -n 1
done

