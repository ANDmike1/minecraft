#!/bin/bash
# Minecraft服务器启动脚本（手动启动）

MC_DIR="/opt/minecraft"
MC_USER="minecraft"

if [ "$EUID" -ne 0 ]; then 
    echo "请使用sudo运行此脚本"
    exit 1
fi

echo "启动Minecraft服务器..."
echo "使用 'screen -r minecraft' 查看服务器控制台"
echo "使用 'screen -S minecraft -X stuff \"stop\$(printf \\\\r)\"' 停止服务器"
echo ""

sudo -u "$MC_USER" screen -dmS minecraft bash -c "cd $MC_DIR && ./start.sh"

sleep 2

if screen -list | grep -q "minecraft"; then
    echo "✓ 服务器已启动"
    echo ""
    echo "常用命令："
    echo "  查看控制台: screen -r minecraft"
    echo "  分离控制台: Ctrl+A 然后按 D"
    echo "  停止服务器: screen -S minecraft -X stuff \"stop\$(printf \\\\r)\""
else
    echo "✗ 服务器启动失败，请检查日志"
    exit 1
fi

