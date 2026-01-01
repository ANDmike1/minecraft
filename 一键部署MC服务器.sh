#!/bin/bash
# Minecraft服务器一键部署脚本
# 自动执行所有安装和配置步骤

set -e

if [ "$EUID" -ne 0 ]; then 
    echo "请使用sudo运行此脚本"
    exit 1
fi

echo "=========================================="
echo "   Minecraft服务器一键部署"
echo "=========================================="
echo ""
echo "此脚本将执行以下操作："
echo "1. 安装Minecraft服务器"
echo "2. 配置防火墙"
echo "3. 配置systemd服务"
echo ""
read -p "按Enter继续，或Ctrl+C取消..."

# 执行安装
echo ""
echo ">>> 步骤1: 安装Minecraft服务器"
bash install_mc_server.sh

# 配置防火墙
echo ""
echo ">>> 步骤2: 配置防火墙"
bash setup_firewall.sh

# 配置systemd
echo ""
echo ">>> 步骤3: 配置systemd服务"
bash setup_systemd.sh

echo ""
echo "=========================================="
echo "部署完成！"
echo "=========================================="
echo ""
echo "下一步："
echo "1. 在阿里云控制台配置安全组，开放TCP端口25565"
echo "2. 启动服务器: sudo systemctl start mc-server"
echo "3. 查看状态: sudo systemctl status mc-server"
echo "4. 查看日志: sudo journalctl -u mc-server -f"
echo ""
echo "服务器配置目录: /opt/minecraft"
echo "配置文件: /opt/minecraft/server.properties"
echo ""
echo "详细说明请查看: MC服务器部署指南.md"
echo ""


