#!/bin/bash
# 检查Minecraft服务器版本

echo "=========================================="
echo "   检查Minecraft服务器版本"
echo "=========================================="
echo ""

# 方法1：从systemd日志中查找
echo "[方法1] 从systemd日志中查找版本..."
VERSION=$(sudo journalctl -u mc-server 2>/dev/null | grep -oP "Starting minecraft server version \K[0-9.]+" | head -1)

if [ -n "$VERSION" ]; then
    echo "✓ 找到版本: $VERSION"
    echo ""
    echo "请在Minecraft客户端中选择版本: $VERSION"
    exit 0
fi

# 方法2：从服务器日志文件中查找
echo "[方法2] 从服务器日志文件中查找版本..."
if [ -f "/opt/minecraft/logs/latest.log" ]; then
    VERSION=$(sudo grep -i "Starting minecraft server version" /opt/minecraft/logs/latest.log 2>/dev/null | grep -oP "version \K[0-9.]+" | head -1)
    
    if [ -n "$VERSION" ]; then
        echo "✓ 找到版本: $VERSION"
        echo ""
        echo "请在Minecraft客户端中选择版本: $VERSION"
        exit 0
    fi
fi

# 方法3：检查server.jar文件信息
echo "[方法3] 检查server.jar文件..."
if [ -f "/opt/minecraft/server.jar" ]; then
    echo "server.jar文件存在"
    ls -lh /opt/minecraft/server.jar
    echo ""
    echo "提示: 根据安装脚本，如果自动获取失败，会使用1.20.4版本"
fi

# 如果都找不到，提供手动检查方法
echo ""
echo "=========================================="
echo "未找到版本信息"
echo "=========================================="
echo ""
echo "请手动检查："
echo ""
echo "1. 查看服务器启动日志："
echo "   sudo journalctl -u mc-server -n 100 | grep -i version"
echo ""
echo "2. 查看服务器日志文件："
echo "   sudo tail -100 /opt/minecraft/logs/latest.log | grep -i version"
echo ""
echo "3. 如果服务器正在运行，尝试连接时会显示版本信息"
echo ""
echo "4. 根据安装脚本，默认可能是 1.20.4 版本"
echo "   可以尝试使用客户端版本 1.20.4 连接"
echo ""


