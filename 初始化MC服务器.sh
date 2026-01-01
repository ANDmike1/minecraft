#!/bin/bash
# 初始化Minecraft服务器（首次运行）

set -e

if [ "$EUID" -ne 0 ]; then 
    echo "请使用sudo运行此脚本"
    exit 1
fi

MC_DIR="/opt/minecraft"
MC_USER="minecraft"

echo "=========================================="
echo "   初始化Minecraft服务器"
echo "=========================================="
echo ""

# 检查目录是否存在
if [ ! -d "$MC_DIR" ]; then
    echo "✗ 服务器目录不存在: $MC_DIR"
    echo "  请先运行安装脚本: sudo bash install_mc_server.sh"
    exit 1
fi

# 检查用户是否存在
if ! id "$MC_USER" &>/dev/null; then
    echo "✗ Minecraft用户不存在"
    echo "  创建用户..."
    useradd -r -m -d "$MC_DIR" -s /bin/bash "$MC_USER"
fi

# 检查并修复权限
echo "[1/4] 检查文件权限..."
chown -R "$MC_USER:$MC_USER" "$MC_DIR"
echo "✓ 权限已修复"
echo ""

# 检查server.jar
echo "[2/4] 检查server.jar..."
if [ ! -f "$MC_DIR/server.jar" ]; then
    echo "✗ server.jar 不存在"
    echo "  正在下载..."
    cd "$MC_DIR"
    sudo -u "$MC_USER" wget -O server.jar https://piston-data.mojang.com/v1/objects/8dd1a28015f51b1803213892b50b7b4fc76e594d/server.jar
    echo "✓ server.jar 已下载"
else
    echo "✓ server.jar 已存在"
    ls -lh "$MC_DIR/server.jar"
fi
echo ""

# 首次运行服务器生成eula.txt
echo "[3/4] 首次运行服务器（生成配置文件）..."
echo "  这可能需要几分钟，请耐心等待..."
cd "$MC_DIR"

# 使用较低内存运行首次启动（避免OOM）
sudo -u "$MC_USER" java -Xmx1024M -Xms512M -jar server.jar nogui || true

# 等待几秒让文件生成
sleep 3

# 检查eula.txt是否生成
if [ -f "$MC_DIR/eula.txt" ]; then
    echo "✓ eula.txt 已生成"
else
    echo "✗ eula.txt 未生成，尝试手动创建..."
    sudo -u "$MC_USER" bash -c "echo 'eula=false' > $MC_DIR/eula.txt"
fi
echo ""

# 接受EULA
echo "[4/4] 接受EULA..."
if [ -f "$MC_DIR/eula.txt" ]; then
    sudo -u "$MC_USER" sed -i 's/eula=false/eula=true/' "$MC_DIR/eula.txt"
    echo "✓ EULA已接受"
    cat "$MC_DIR/eula.txt"
else
    echo "✗ 无法找到eula.txt"
    exit 1
fi
echo ""

# 检查并创建server.properties（如果不存在）
if [ ! -f "$MC_DIR/server.properties" ]; then
    echo "创建默认server.properties..."
    sudo -u "$MC_USER" java -Xmx1024M -Xms512M -jar server.jar nogui || true
    sleep 2
fi

echo ""
echo "=========================================="
echo "初始化完成！"
echo "=========================================="
echo ""
echo "下一步："
echo "1. 检查配置: sudo nano /opt/minecraft/server.properties"
echo "2. 启动服务器: sudo systemctl start mc-server"
echo "3. 查看状态: sudo systemctl status mc-server"
echo ""

