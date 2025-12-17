#!/bin/bash

# 功能: 安装 frpc
function install_frp {
    echo "-----------------------------------"
    echo "开始安装 frp client..."
    
    # 检查目标目录是否存在，如果不存在则创建
    if [[ ! -d "/etc/ss" ]]; then
        sudo mkdir -p "/etc/ss"
    fi
    
    # 动态获取当前主机名
    HOSTNAME=$(hostname)
    REMOTE_PORT=$((RANDOM % 55536 + 10000))
    
    # 下载 frpc
    sudo wget -P /etc/ss -N --no-check-certificate https://github.com/ichbinkk/FFD/releases/download/v1.0/frpc
    sudo chmod +x /etc/ss/frpc
    
    # Step 1: 创建 frpc.ini
    FILE_PATH="/etc/ss/frpc.ini"
    sudo bash -c "cat > $FILE_PATH << EOF
[common]
server_addr = v1.821321.xyz
server_port = 5443
token = dls5jB6naABf5NU3

[$HOSTNAME-ssh]
type = tcp
local_ip = 127.0.0.1
local_port = 22
remote_port = $REMOTE_PORT
EOF"
    
    if [[ -s "$FILE_PATH" ]]; then
        echo "frpc.ini 文件已保存到 $FILE_PATH"
    else
        echo "错误：$FILE_PATH 创建失败。"
        return 1
    fi
    
    # Step 2: 创建 frpc.service
    SERVICE_PATH="/etc/systemd/system/frpc.service"        
    sudo bash -c "cat > $SERVICE_PATH << EOF
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
EOF"
    
    sudo systemctl daemon-reload
    sudo systemctl enable frpc.service
    sudo systemctl restart frpc.service    

    # Step 3: 添加定时重启任务 (Crontab) - 增加去重处理
    (crontab -l 2>/dev/null | grep -v "systemctl restart frpc.service"; echo "0 */2 * * * systemctl restart frpc.service &> /dev/null") | crontab -
    echo "安装完成！"
    echo "-----------------------------------"
}

# 功能: 卸载 frpc
function uninstall_frp {
    echo "-----------------------------------"
    echo "开始卸载 frp client..."

    # 1. 停止并禁用服务
    sudo systemctl stop frpc.service 2>/dev/null
    sudo systemctl disable frpc.service 2>/dev/null
    
    # 2. 删除服务文件
    if [[ -f "/etc/systemd/system/frpc.service" ]]; then
        sudo rm "/etc/systemd/system/frpc.service"
        sudo systemctl daemon-reload
        echo "已删除 systemd 服务文件。"
    fi

    # 3. 删除安装目录和文件
    if [[ -d "/etc/ss" ]]; then
        sudo rm -rf "/etc/ss"
        echo "已删除安装目录 /etc/ss"
    fi

    # 4. 清理 crontab 任务
    crontab -l 2>/dev/null | grep -v "systemctl restart frpc.service" | crontab -
    echo "已清理相关的计划任务。"

    echo "卸载完成！"
    echo "-----------------------------------"
}

# --- 主程序循环 ---
while true; do
    echo "=============================="
    echo "      frpc 管理脚本           "
    echo "=============================="
    echo "  1. 安装 frpc"
    echo "  2. 卸载 frpc"
    echo "  0. 退出程序"
    echo "=============================="
    read -p "请输入您的选择 (0-2): " choice

    case $choice in
        1)
            install_frp
            exit 0  # 执行完安装后退出，如需继续操作可改为 break
            ;;
        2)
            uninstall_frp
            exit 0  # 执行完卸载后退出
            ;;
        0)
            echo "退出程序。"
            exit 0
            ;;
        *)
            echo "无效输入，请输入 0、1 或 2。"
            ;;
    esac
done