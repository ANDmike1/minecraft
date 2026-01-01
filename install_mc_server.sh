#!/bin/bash
# Minecraft服务器安装脚本
# 适用于Ubuntu 22.04
# 2核2GB配置优化

set -e

# 设置非交互式模式，避免安装过程中的交互式提示
export DEBIAN_FRONTEND=noninteractive

echo "=========================================="
echo "    Minecraft服务器安装脚本"
echo "=========================================="
echo ""

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo "请使用sudo运行此脚本"
    exit 1
fi

# 更新系统
echo "[1/7] 更新系统包..."
# 使用非交互式模式，自动处理服务重启提示
apt update && apt upgrade -y -o Dpkg::Options::="--force-confold"

# 安装必要的工具
echo "[2/7] 安装必要工具..."
apt install -y -o Dpkg::Options::="--force-confold" wget curl screen nano ufw

# 安装Java 17 (Minecraft 1.18+推荐)
echo "[3/7] 安装Java 17..."
apt install -y -o Dpkg::Options::="--force-confold" openjdk-17-jdk

# 验证Java安装
java -version
echo ""

# 创建Minecraft服务器目录
MC_DIR="/opt/minecraft"
MC_USER="minecraft"

echo "[4/7] 创建Minecraft用户和目录..."
if ! id "$MC_USER" &>/dev/null; then
    useradd -r -m -d "$MC_DIR" -s /bin/bash "$MC_USER"
else
    echo "用户 $MC_USER 已存在"
fi

mkdir -p "$MC_DIR"
chown -R "$MC_USER:$MC_USER" "$MC_DIR"

# 切换到Minecraft目录
cd "$MC_DIR"

# 下载Minecraft服务器jar文件（最新版本）
echo "[5/7] 下载Minecraft服务器..."
echo "正在获取最新版本信息..."

# 获取最新版本信息
LATEST_VERSION=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | grep -oP '"release":\s*"[^"]*"' | head -1 | grep -oP '"\K[^"]+')
LATEST_VERSION_URL=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | grep -A 2 "\"id\": \"$LATEST_VERSION\"" | grep -oP '"url":\s*"\K[^"]+')
SERVER_JAR_URL=$(curl -s "$LATEST_VERSION_URL" | grep -oP '"server":\s*\{\s*"sha1":\s*"[^"]*",\s*"size":\s*\d+,\s*"url":\s*"\K[^"]+')

if [ -z "$SERVER_JAR_URL" ]; then
    echo "无法获取服务器下载链接，使用备用方法..."
    # 备用：直接下载1.20.4版本
    SERVER_JAR_URL="https://piston-data.mojang.com/v1/objects/8dd1a28015f51b1803213892b50b7b4fc76e594d/server.jar"
    LATEST_VERSION="1.20.4"
fi

echo "检测到最新版本: $LATEST_VERSION"
echo "正在下载服务器文件..."

sudo -u "$MC_USER" wget -O server.jar "$SERVER_JAR_URL"

# 首次运行以生成eula.txt和server.properties
echo "[6/7] 初始化服务器配置..."
sudo -u "$MC_USER" java -Xmx1024M -Xms1024M -jar server.jar nogui || true

# 接受EULA
echo "[7/7] 配置服务器..."
sudo -u "$MC_USER" sed -i 's/eula=false/eula=true/' eula.txt

# 优化server.properties配置（针对2GB内存）
sudo -u "$MC_USER" cat > server.properties << 'EOF'
# Minecraft服务器配置 - 2GB内存优化
motd=Minecraft Server on Ubuntu
difficulty=normal
gamemode=survival
force-gamemode=false
hardcore=false
pvp=true
spawn-protection=16
max-tick-time=60000
enable-query=false
enable-rcon=false
enable-command-block=false
max-players=10
network-compression-threshold=256
resource-pack-sha1=
max-world-size=29999984
function-permission-level=2
rcon.port=25575
server-port=25565
server-ip=
spawn-npcs=true
spawn-animals=true
spawn-monsters=true
spawn-villagers=true
view-distance=8
simulation-distance=6
generate-structures=true
online-mode=true
allow-flight=false
max-build-height=256
level-seed=
prevent-proxy-connections=false
use-native-transport=true
enable-jmx-monitoring=false
enable-status=true
broadcast-rcon-to-ops=true
broadcast-console-to-ops=true
resource-pack=
entity-broadcast-range-percentage=100
player-idle-timeout=0
debug=false
rate-limit=0
hardmax-tick-time=180000
EOF

chown "$MC_USER:$MC_USER" server.properties

# 创建启动脚本
sudo -u "$MC_USER" cat > start.sh << 'EOF'
#!/bin/bash
# Minecraft服务器启动脚本

cd /opt/minecraft

# 内存配置：2GB服务器，为系统预留512MB，Minecraft使用1.5GB
# -Xmx1536M: 最大堆内存1.5GB
# -Xms1536M: 初始堆内存1.5GB（避免动态调整）
# -XX:+UseG1GC: 使用G1垃圾收集器（适合低内存）
# -XX:+ParallelRefProcEnabled: 并行处理引用
# -XX:MaxGCPauseMillis=200: 最大GC暂停时间
# -XX:+UnlockExperimentalVMOptions: 解锁实验性选项
# -XX:+DisableExplicitGC: 禁用显式GC
# -XX:+AlwaysPreTouch: 预分配内存
# -XX:G1NewSizePercent=30: G1新生代最小比例
# -XX:G1MaxNewSizePercent=40: G1新生代最大比例
# -XX:G1HeapRegionSize=8M: G1堆区域大小
# -XX:G1ReservePercent=20: G1保留区域比例
# -XX:G1HeapWastePercent=5: G1堆浪费比例
# -XX:G1MixedGCCountTarget=4: 混合GC目标次数
# -XX:InitiatingHeapOccupancyPercent=15: 触发并发标记的堆占用比例
# -XX:G1MixedGCLiveThresholdPercent=90: 混合GC存活阈值
# -XX:G1RSetUpdatingPauseTimePercent=5: G1 RSet更新时间比例
# -XX:SurvivorRatio=32: 幸存者区比例
# -XX:+PerfDisableSharedMem: 禁用共享内存（减少内存使用）
# -XX:MaxTenuringThreshold=1: 最大晋升年龄
# -Dusing.aikars.flags=https://mcflags.emc.gs: Aikar的JVM参数优化

java -Xmx1536M -Xms1536M \
     -XX:+UseG1GC \
     -XX:+ParallelRefProcEnabled \
     -XX:MaxGCPauseMillis=200 \
     -XX:+UnlockExperimentalVMOptions \
     -XX:+DisableExplicitGC \
     -XX:+AlwaysPreTouch \
     -XX:G1NewSizePercent=30 \
     -XX:G1MaxNewSizePercent=40 \
     -XX:G1HeapRegionSize=8M \
     -XX:G1ReservePercent=20 \
     -XX:G1HeapWastePercent=5 \
     -XX:G1MixedGCCountTarget=4 \
     -XX:InitiatingHeapOccupancyPercent=15 \
     -XX:G1MixedGCLiveThresholdPercent=90 \
     -XX:G1RSetUpdatingPauseTimePercent=5 \
     -XX:SurvivorRatio=32 \
     -XX:+PerfDisableSharedMem \
     -XX:MaxTenuringThreshold=1 \
     -Dusing.aikars.flags=https://mcflags.emc.gs \
     -jar server.jar nogui
EOF

chmod +x start.sh
chown "$MC_USER:$MC_USER" start.sh

# 创建停止脚本
sudo -u "$MC_USER" cat > stop.sh << 'EOF'
#!/bin/bash
# Minecraft服务器停止脚本

screen -S minecraft -X stuff "stop$(printf \\r)"
EOF

chmod +x stop.sh
chown "$MC_USER:$MC_USER" stop.sh

echo ""
echo "=========================================="
echo "安装完成！"
echo "=========================================="
echo ""
echo "服务器目录: $MC_DIR"
echo "服务器用户: $MC_USER"
echo ""
echo "下一步操作："
echo "1. 配置防火墙（运行: sudo bash setup_firewall.sh）"
echo "2. 配置systemd服务（运行: sudo bash setup_systemd.sh）"
echo "3. 启动服务器（运行: sudo systemctl start mc-server）"
echo ""
echo "或者手动启动："
echo "  sudo -u $MC_USER screen -S minecraft $MC_DIR/start.sh"
echo ""

