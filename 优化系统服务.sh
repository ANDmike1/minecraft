#!/bin/bash
# 优化系统服务 - 关闭不必要的服务，只保留MC服务器必需的服务

set -e

if [ "$EUID" -ne 0 ]; then 
    echo "请使用sudo运行此脚本"
    exit 1
fi

echo "=========================================="
echo "   优化系统服务 - 释放内存"
echo "=========================================="
echo ""

# 检查当前内存
echo "[检查] 当前内存使用..."
free -h
echo ""

# 定义可以安全关闭的服务
SERVICES_TO_STOP=(
    "docker.service"              # Docker（如果不用）
    "containerd.service"           # 容器运行时（如果不用）
    "snapd.service"               # Snap包管理
    "fwupd.service"               # 固件更新守护进程
    "packagekit.service"           # 包管理守护进程
    "ModemManager.service"         # 调制解调器管理（云服务器不需要）
    "tuned.service"               # 动态系统调优
    "udisks2.service"             # 磁盘管理（云服务器通常不需要）
    "unattended-upgrades.service" # 自动更新（可以关闭节省资源）
    "atd.service"                # 延迟执行调度器
)

# 定义需要禁用的服务（防止开机自启）
SERVICES_TO_DISABLE=(
    "docker.service"
    "containerd.service"
    "snapd.service"
    "fwupd.service"
    "packagekit.service"
    "ModemManager.service"
    "tuned.service"
    "udisks2.service"
    "unattended-upgrades.service"
    "atd.service"
)

# 必需保留的服务（不会关闭）
REQUIRED_SERVICES=(
    "ssh.service"                 # SSH（必须！否则无法远程管理）
    "systemd-journald.service"    # 系统日志
    "systemd-logind.service"       # 用户登录管理
    "systemd-networkd.service"    # 网络配置
    "systemd-resolved.service"     # DNS解析
    "systemd-udevd.service"       # 设备管理
    "dbus.service"                # 系统消息总线
    "rsyslog.service"             # 系统日志
    "cron.service"                # 定时任务
    "chrony.service"              # 时间同步
    "aliyun.service"              # 阿里云服务（建议保留）
    "AssistDaemon.service"        # 阿里云助手（建议保留）
)

echo "=========================================="
echo "将关闭以下服务以释放内存："
echo "=========================================="
for service in "${SERVICES_TO_STOP[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo "  - $service (运行中)"
    else
        echo "  - $service (未运行)"
    fi
done
echo ""

echo "=========================================="
echo "将保留以下必需服务："
echo "=========================================="
for service in "${REQUIRED_SERVICES[@]}"; do
    echo "  ✓ $service"
done
echo ""

read -p "确认关闭上述服务? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "操作已取消"
    exit 1
fi

echo ""
echo "=========================================="
echo "开始优化..."
echo "=========================================="
echo ""

# 停止服务
STOPPED_COUNT=0
for service in "${SERVICES_TO_STOP[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo "停止 $service..."
        systemctl stop "$service" 2>/dev/null && {
            echo "  ✓ 已停止"
            STOPPED_COUNT=$((STOPPED_COUNT + 1))
        } || echo "  ✗ 停止失败（可能已停止）"
    else
        echo "$service 未运行，跳过"
    fi
done

echo ""

# 禁用服务（防止开机自启）
DISABLED_COUNT=0
for service in "${SERVICES_TO_DISABLE[@]}"; do
    if systemctl is-enabled --quiet "$service" 2>/dev/null; then
        echo "禁用 $service（防止开机自启）..."
        systemctl disable "$service" 2>/dev/null && {
            echo "  ✓ 已禁用"
            DISABLED_COUNT=$((DISABLED_COUNT + 1))
        } || echo "  ✗ 禁用失败"
    fi
done

echo ""
echo "=========================================="
echo "优化完成！"
echo "=========================================="
echo ""
echo "已停止 $STOPPED_COUNT 个服务"
echo "已禁用 $DISABLED_COUNT 个服务"
echo ""

# 显示优化后的内存
echo "[检查] 优化后的内存使用..."
free -h
echo ""

# 显示当前运行的服务
echo "[检查] 当前运行的服务："
systemctl list-units --type=service --state=running --no-pager | head -20
echo ""

echo "=========================================="
echo "下一步："
echo "=========================================="
echo "1. 现在可以尝试启动Minecraft服务器："
echo "   sudo systemctl start mc-server"
echo ""
echo "2. 如果仍然内存不足，进一步降低MC内存配置："
echo "   sudo nano /etc/systemd/system/mc-server.service"
echo "   将 -Xmx1024M 改为 -Xmx768M 或 -Xmx512M"
echo ""
echo "3. 或者运行紧急修复脚本："
echo "   sudo bash 紧急修复内存问题.sh"
echo ""


