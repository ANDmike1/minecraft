#!/bin/bash
# 配置防火墙规则

set -e

if [ "$EUID" -ne 0 ]; then 
    echo "请使用sudo运行此脚本"
    exit 1
fi

echo "配置防火墙规则..."

# 启用UFW（如果未启用）
ufw --force enable

# 允许SSH（重要！避免被锁在外面）
ufw allow 22/tcp comment 'SSH'

# 允许Minecraft服务器端口
ufw allow 25565/tcp comment 'Minecraft Server'

# 显示规则
echo ""
echo "当前防火墙规则："
ufw status numbered

echo ""
echo "✓ 防火墙配置完成"
echo ""
echo "注意："
echo "  - 如果使用阿里云，还需要在阿里云控制台配置安全组规则"
echo "  - 允许TCP端口: 25565"
echo ""


