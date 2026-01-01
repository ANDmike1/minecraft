#!/bin/bash
# 紧急修复：进一步降低内存配置

set -e

if [ "$EUID" -ne 0 ]; then 
    echo "请使用sudo运行此脚本"
    exit 1
fi

echo "=========================================="
echo "   紧急修复：进一步降低内存配置"
echo "=========================================="
echo ""

# 1. 检查系统内存
echo "[1/5] 检查系统内存..."
echo "----------------------------------------"
free -h
echo ""

TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
AVAIL_MEM=$(free -m | awk '/^Mem:/{print $7}')
USED_MEM=$(free -m | awk '/^Mem:/{print $3}')

echo "总内存: ${TOTAL_MEM}MB"
echo "已用内存: ${USED_MEM}MB"
echo "可用内存: ${AVAIL_MEM}MB"
echo ""

# 2. 检查OOM日志
echo "[2/5] 检查OOM Killer日志..."
echo "----------------------------------------"
dmesg | tail -20 | grep -i oom || echo "未找到最近的OOM记录"
echo ""

# 3. 检查占用内存的进程
echo "[3/5] 检查占用内存的进程（前10个）..."
echo "----------------------------------------"
ps aux --sort=-%mem | head -11
echo ""

# 4. 停止服务器
echo "[4/5] 停止服务器..."
systemctl stop mc-server 2>/dev/null || true
sleep 2
echo "✓ 服务器已停止"
echo ""

# 5. 计算更保守的内存配置
echo "[5/5] 计算保守内存配置..."
echo "----------------------------------------"

# 根据可用内存计算
if [ $AVAIL_MEM -lt 600 ]; then
    MC_MEM=512
    echo "⚠️  可用内存很少，使用512MB配置"
elif [ $AVAIL_MEM -lt 800 ]; then
    MC_MEM=640
    echo "⚠️  可用内存较少，使用640MB配置"
elif [ $AVAIL_MEM -lt 1000 ]; then
    MC_MEM=768
    echo "使用768MB配置"
else
    MC_MEM=896
    echo "使用896MB配置"
fi

echo "Minecraft内存配置: ${MC_MEM}MB"
echo ""

# 6. 更新systemd服务配置
echo "[6/6] 更新systemd服务配置..."
echo "----------------------------------------"

# 备份
if [ -f "/etc/systemd/system/mc-server.service" ]; then
    cp /etc/systemd/system/mc-server.service /etc/systemd/system/mc-server.service.backup.$(date +%Y%m%d_%H%M%S)
fi

# 创建更保守的配置
cat > /etc/systemd/system/mc-server.service << EOF
[Unit]
Description=Minecraft Server
After=network.target

[Service]
Type=simple
User=minecraft
WorkingDirectory=/opt/minecraft
ExecStart=/usr/bin/java -Xmx${MC_MEM}M -Xms${MC_MEM}M -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -jar /opt/minecraft/server.jar nogui
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
echo "  内存配置: -Xmx${MC_MEM}M -Xms${MC_MEM}M"
echo "  （移除了部分优化参数以节省内存）"
echo ""

# 重新加载systemd
systemctl daemon-reload
echo "✓ systemd已重新加载"
echo ""

# 7. 检查swap
echo "[额外] 检查swap配置..."
echo "----------------------------------------"
swapon --show
if [ -z "$(swapon --show)" ]; then
    echo "⚠️  未检测到swap，建议创建swap以增加可用内存"
    echo ""
    read -p "是否创建2GB swap文件? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "创建swap文件..."
        fallocate -l 2G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
        echo "✓ Swap已创建并启用"
        free -h
    fi
fi
echo ""

echo "=========================================="
echo "修复完成！"
echo "=========================================="
echo ""
echo "下一步操作："
echo "1. 启动服务器: sudo systemctl start mc-server"
echo "2. 等待10-20秒让服务器启动"
echo "3. 查看状态: sudo systemctl status mc-server"
echo "4. 查看日志: sudo journalctl -u mc-server -f"
echo ""
echo "如果仍然失败，请："
echo "- 检查系统日志: dmesg | tail -50"
echo "- 关闭其他服务释放内存"
echo "- 考虑升级服务器配置"
echo ""


