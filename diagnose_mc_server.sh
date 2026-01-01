#!/bin/bash
# Minecraft服务器诊断脚本

echo "=========================================="
echo "   Minecraft服务器诊断工具"
echo "=========================================="
echo ""

# 1. 检查服务状态
echo "[1] 检查服务状态..."
echo "----------------------------------------"
sudo systemctl status mc-server --no-pager -l | head -25
echo ""

# 2. 查看最新日志
echo "[2] 查看最新日志（最后30行）..."
echo "----------------------------------------"
sudo journalctl -u mc-server -n 30 --no-pager
echo ""

# 3. 检查server.jar
echo "[3] 检查server.jar文件..."
echo "----------------------------------------"
if [ -f "/opt/minecraft/server.jar" ]; then
    echo "✓ server.jar 存在"
    ls -lh /opt/minecraft/server.jar
    file /opt/minecraft/server.jar
else
    echo "✗ server.jar 不存在！"
    echo "  需要重新下载服务器文件"
fi
echo ""

# 4. 检查eula.txt
echo "[4] 检查EULA..."
echo "----------------------------------------"
if [ -f "/opt/minecraft/eula.txt" ]; then
    cat /opt/minecraft/eula.txt
    if grep -q "eula=true" /opt/minecraft/eula.txt; then
        echo "✓ EULA已接受"
    else
        echo "✗ EULA未接受 - 这是常见问题！"
        echo ""
        echo "修复命令:"
        echo "  sudo sed -i 's/eula=false/eula=true/' /opt/minecraft/eula.txt"
    fi
else
    echo "✗ eula.txt 不存在"
    echo "  需要首次运行服务器生成此文件"
fi
echo ""

# 5. 检查Java
echo "[5] 检查Java环境..."
echo "----------------------------------------"
if command -v java &> /dev/null; then
    echo "✓ Java已安装"
    java -version 2>&1 | head -3
    echo "Java路径: $(which java)"
else
    echo "✗ Java未安装"
    echo ""
    echo "修复命令:"
    echo "  sudo apt update"
    echo "  sudo apt install -y openjdk-17-jdk"
fi
echo ""

# 6. 检查权限
echo "[6] 检查文件权限..."
echo "----------------------------------------"
ls -ld /opt/minecraft
echo ""
echo "目录内容:"
ls -la /opt/minecraft/ | head -15
echo ""

# 7. 检查systemd服务文件
echo "[7] 检查systemd服务配置..."
echo "----------------------------------------"
if [ -f "/etc/systemd/system/mc-server.service" ]; then
    echo "✓ 服务文件存在"
    echo ""
    echo "工作目录:"
    grep "WorkingDirectory" /etc/systemd/system/mc-server.service || echo "未设置WorkingDirectory"
    echo ""
    echo "执行命令:"
    grep "ExecStart" /etc/systemd/system/mc-server.service | head -1
else
    echo "✗ 服务文件不存在"
    echo "  需要运行: sudo bash setup_systemd.sh"
fi
echo ""

# 8. 检查内存
echo "[8] 检查系统资源..."
echo "----------------------------------------"
echo "内存使用:"
free -h
echo ""
echo "磁盘空间:"
df -h /opt/minecraft
echo ""

# 9. 检查端口
echo "[9] 检查端口占用..."
echo "----------------------------------------"
if command -v netstat &> /dev/null; then
    sudo netstat -tlnp | grep 25565 || echo "端口25565未被占用"
elif command -v ss &> /dev/null; then
    sudo ss -tlnp | grep 25565 || echo "端口25565未被占用"
else
    echo "无法检查端口（netstat和ss都不可用）"
fi
echo ""

# 10. 尝试手动启动测试
echo "[10] 建议的手动测试..."
echo "----------------------------------------"
echo "如果以上检查都正常，可以尝试手动启动测试："
echo ""
echo "  sudo -u minecraft bash -c 'cd /opt/minecraft && java -Xmx1536M -Xms1536M -jar server.jar nogui'"
echo ""
echo "这会显示具体的错误信息"
echo ""

echo "=========================================="
echo "诊断完成！"
echo "=========================================="
echo ""
echo "常见修复命令:"
echo "  1. 接受EULA: sudo sed -i 's/eula=false/eula=true/' /opt/minecraft/eula.txt"
echo "  2. 修复权限: sudo chown -R minecraft:minecraft /opt/minecraft"
echo "  3. 重新加载服务: sudo systemctl daemon-reload"
echo "  4. 重启服务: sudo systemctl restart mc-server"
echo "  5. 查看实时日志: sudo journalctl -u mc-server -f"
echo ""

