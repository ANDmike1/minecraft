#!/bin/bash
# 修复Minecraft服务器内存不足问题

set -e

if [ "$EUID" -ne 0 ]; then 
    echo "请使用sudo运行此脚本"
    exit 1
fi

echo "=========================================="
echo "   修复Minecraft服务器内存不足问题"
echo "=========================================="
echo ""

# 1. 检查系统内存
echo "[1/4] 检查系统内存..."
echo "----------------------------------------"
free -h
echo ""

TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
AVAIL_MEM=$(free -m | awk '/^Mem:/{print $7}')

echo "总内存: ${TOTAL_MEM}MB"
echo "可用内存: ${AVAIL_MEM}MB"
echo ""

# 2. 计算推荐内存
echo "[2/4] 计算推荐内存配置..."
echo "----------------------------------------"

# 为系统预留至少512MB
RESERVED_MEM=512
RECOMMENDED_MEM=$((TOTAL_MEM - RESERVED_MEM))

# 如果总内存小于2GB，使用更保守的配置
if [ $TOTAL_MEM -lt 2048 ]; then
    RECOMMENDED_MEM=1024
    echo "⚠️  检测到内存小于2GB，使用保守配置"
fi

echo "推荐Minecraft内存: ${RECOMMENDED_MEM}MB"
echo ""

# 3. 停止当前服务
echo "[3/4] 停止当前服务..."
systemctl stop mc-server 2>/dev/null || true
sleep 2
echo "✓ 服务已停止"
echo ""

# 4. 更新systemd服务配置
echo "[4/4] 更新systemd服务配置..."
echo "----------------------------------------"

# 备份原配置
if [ -f "/etc/systemd/system/mc-server.service" ]; then
    cp /etc/systemd/system/mc-server.service /etc/systemd/system/mc-server.service.backup
    echo "✓ 已备份原配置"
fi

# 创建新的服务配置（降低内存）
cat > /etc/systemd/system/mc-server.service << EOF
[Unit]
Description=Minecraft Server
After=network.target

[Service]
Type=simple
User=minecraft
WorkingDirectory=/opt/minecraft
ExecStart=/usr/bin/java -Xmx${RECOMMENDED_MEM}M -Xms${RECOMMENDED_MEM}M -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -jar /opt/minecraft/server.jar nogui
Restart=on-failure
RestartSec=30

# 资源限制
LimitNOFILE=65536

# 日志
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "✓ 服务配置已更新"
echo "  内存配置: -Xmx${RECOMMENDED_MEM}M -Xms${RECOMMENDED_MEM}M"
echo ""

# 重新加载systemd
systemctl daemon-reload
echo "✓ systemd已重新加载"
echo ""

# 5. 检查其他占用内存的进程
echo "[额外] 检查占用内存的进程..."
echo "----------------------------------------"
ps aux --sort=-%mem | head -10
echo ""

echo "=========================================="
echo "修复完成！"
echo "=========================================="
echo ""
echo "下一步操作："
echo "1. 启动服务器: sudo systemctl start mc-server"
echo "2. 查看状态: sudo systemctl status mc-server"
echo "3. 查看日志: sudo journalctl -u mc-server -f"
echo ""
echo "如果仍然失败，可能需要："
echo "- 关闭其他占用内存的服务"
echo "- 进一步降低内存配置"
echo "- 检查系统日志: dmesg | grep -i oom"
echo ""


