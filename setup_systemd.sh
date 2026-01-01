#!/bin/bash
# 设置Minecraft服务器为systemd服务

set -e

if [ "$EUID" -ne 0 ]; then 
    echo "请使用sudo运行此脚本"
    exit 1
fi

MC_DIR="/opt/minecraft"
MC_USER="minecraft"

echo "创建systemd服务..."

# 创建systemd服务文件
cat > /etc/systemd/system/mc-server.service << EOF
[Unit]
Description=Minecraft Server
After=network.target

[Service]
Type=simple
User=$MC_USER
WorkingDirectory=$MC_DIR
ExecStart=/usr/bin/java -Xmx1536M -Xms1536M -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -jar $MC_DIR/server.jar nogui
Restart=on-failure
RestartSec=10

# 资源限制
LimitNOFILE=65536

# 日志
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd
systemctl daemon-reload

# 启用服务（开机自启）
systemctl enable mc-server.service

echo ""
echo "✓ systemd服务已创建并启用"
echo ""
echo "服务管理命令："
echo "  启动服务器: sudo systemctl start mc-server"
echo "  停止服务器: sudo systemctl stop mc-server"
echo "  重启服务器: sudo systemctl restart mc-server"
echo "  查看状态:   sudo systemctl status mc-server"
echo "  查看日志:   sudo journalctl -u mc-server -f"
echo "  禁用自启:   sudo systemctl disable mc-server"
echo ""

