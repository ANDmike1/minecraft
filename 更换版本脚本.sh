#!/bin/bash
# Minecraft服务器版本更换脚本

set -e

if [ "$EUID" -ne 0 ]; then 
    echo "请使用sudo运行此脚本"
    exit 1
fi

MC_DIR="/opt/minecraft"
MC_USER="minecraft"

echo "=========================================="
echo "   Minecraft服务器版本更换工具"
echo "=========================================="
echo ""

# 检查当前版本
echo "[1/8] 检查当前服务器版本..."
CURRENT_VERSION=$(sudo journalctl -u mc-server 2>/dev/null | grep -oP "Starting minecraft server version \K[0-9.]+" | head -1)
if [ -n "$CURRENT_VERSION" ]; then
    echo "当前版本: $CURRENT_VERSION"
else
    echo "无法确定当前版本"
fi
echo ""

# 停止服务器
echo "[2/8] 停止服务器..."
systemctl stop mc-server 2>/dev/null || true
sleep 2
echo "✓ 服务器已停止"
echo ""

# 备份
echo "[3/8] 备份当前服务器..."
BACKUP_FILE="/opt/minecraft-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf "$BACKUP_FILE" -C /opt minecraft
echo "✓ 备份完成: $BACKUP_FILE"
echo ""

# 选择操作类型
echo "[4/8] 选择操作类型..."
echo "1. 更换原版服务器版本"
echo "2. 安装Forge服务器"
echo "3. 安装Fabric服务器"
echo "4. 仅更新server.jar文件"
read -p "请选择 (1-4): " OPTION

case $OPTION in
    1)
        echo ""
        read -p "请输入新版本号 (如 1.21): " NEW_VERSION
        echo "正在下载 $NEW_VERSION 版本..."
        # 这里需要根据实际API获取下载链接
        echo "⚠️  请手动下载对应版本的server.jar"
        echo "   下载链接: https://piston-data.mojang.com/v1/objects/..."
        read -p "按Enter继续（假设已下载server.jar）..."
        ;;
    2)
        echo ""
        read -p "请输入Minecraft版本 (如 1.20.1): " MC_VERSION
        read -p "请输入Forge版本 (如 47.1.0): " FORGE_VERSION
        FORGE_VERSION_FULL="${MC_VERSION}-${FORGE_VERSION}"
        echo "正在下载Forge $FORGE_VERSION_FULL..."
        
        cd "$MC_DIR"
        FORGE_INSTALLER="forge-${FORGE_VERSION_FULL}-installer.jar"
        FORGE_JAR="forge-${FORGE_VERSION_FULL}.jar"
        
        # 下载安装器
        echo "下载Forge安装器..."
        sudo -u "$MC_USER" wget -O "$FORGE_INSTALLER" "https://maven.minecraftforge.net/net/minecraftforge/forge/${FORGE_VERSION_FULL}/${FORGE_INSTALLER}" || {
            echo "下载失败，请检查版本号"
            exit 1
        }
        
        # 安装Forge
        echo "安装Forge服务器..."
        sudo -u "$MC_USER" java -jar "$FORGE_INSTALLER" --installServer
        
        # 清理安装器
        rm -f "$FORGE_INSTALLER"
        
        echo "✓ Forge已安装: $FORGE_JAR"
        NEW_JAR="$FORGE_JAR"
        ;;
    3)
        echo ""
        read -p "请输入Minecraft版本 (如 1.20.1): " MC_VERSION
        read -p "请输入Fabric Loader版本 (如 0.14.22): " FABRIC_LOADER
        
        cd "$MC_DIR"
        FABRIC_INSTALLER="fabric-installer.jar"
        
        echo "下载Fabric安装器..."
        sudo -u "$MC_USER" wget -O "$FABRIC_INSTALLER" "https://maven.fabricmc.net/net/fabricmc/fabric-installer/0.11.2/fabric-installer-0.11.2.jar"
        
        echo "安装Fabric服务器..."
        sudo -u "$MC_USER" java -jar "$FABRIC_INSTALLER" server -mcversion "$MC_VERSION" -loader "$FABRIC_LOADER"
        
        rm -f "$FABRIC_INSTALLER"
        
        echo "✓ Fabric已安装"
        NEW_JAR="fabric-server-launch.jar"
        ;;
    4)
        echo ""
        read -p "请输入server.jar的完整路径或URL: " JAR_PATH
        
        cd "$MC_DIR"
        if [[ "$JAR_PATH" =~ ^https?:// ]]; then
            echo "从URL下载..."
            sudo -u "$MC_USER" wget -O server.jar "$JAR_PATH"
        else
            echo "从本地路径复制..."
            sudo -u "$MC_USER" cp "$JAR_PATH" server.jar
        fi
        
        NEW_JAR="server.jar"
        ;;
    *)
        echo "无效选项"
        exit 1
        ;;
esac

# 创建mods目录（整合包需要）
if [ "$OPTION" == "2" ] || [ "$OPTION" == "3" ]; then
    echo ""
    echo "[5/8] 创建mods和config目录..."
    sudo -u "$MC_USER" mkdir -p "$MC_DIR/mods"
    sudo -u "$MC_USER" mkdir -p "$MC_DIR/config"
    echo "✓ 目录已创建"
fi

# 更新systemd服务配置
echo ""
echo "[6/8] 更新systemd服务配置..."

# 备份原配置
cp /etc/systemd/system/mc-server.service /etc/systemd/system/mc-server.service.backup

# 读取当前内存配置
CURRENT_MEM=$(grep -oP 'Xmx\K[0-9]+M' /etc/systemd/system/mc-server.service | head -1)
if [ -z "$CURRENT_MEM" ]; then
    CURRENT_MEM="1024M"
fi

# 如果是整合包，可能需要更多内存
if [ "$OPTION" == "2" ] || [ "$OPTION" == "3" ]; then
    read -p "整合包需要更多内存，当前: $CURRENT_MEM，是否增加? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "请输入新内存配置 (如 1536M): " NEW_MEM
        CURRENT_MEM="$NEW_MEM"
    fi
fi

# 更新jar文件名
sed -i "s|/opt/minecraft/server.jar|/opt/minecraft/$NEW_JAR|g" /etc/systemd/system/mc-server.service

# 更新内存配置（如果修改了）
if [ -n "$NEW_MEM" ]; then
    sed -i "s/-Xmx[0-9]\+M/-Xmx${NEW_MEM%/M}M/g" /etc/systemd/system/mc-server.service
    sed -i "s/-Xms[0-9]\+M/-Xms${NEW_MEM%/M}M/g" /etc/systemd/system/mc-server.service
fi

echo "✓ systemd配置已更新"
echo ""

# 首次运行
echo "[7/8] 首次运行服务器（生成配置文件）..."
cd "$MC_DIR"
echo "这可能需要几分钟，请耐心等待..."
sudo -u "$MC_USER" java -Xmx${CURRENT_MEM%/M}M -Xms${CURRENT_MEM%/M}M -jar "$NEW_JAR" nogui || true

# 等待文件生成
sleep 3

# 接受EULA
echo ""
echo "[8/8] 接受EULA..."
if [ -f "$MC_DIR/eula.txt" ]; then
    sudo -u "$MC_USER" sed -i 's/eula=false/eula=true/' "$MC_DIR/eula.txt"
    echo "✓ EULA已接受"
else
    echo "⚠️  eula.txt未生成，请手动创建"
fi

# 重新加载systemd
systemctl daemon-reload

echo ""
echo "=========================================="
echo "版本更换完成！"
echo "=========================================="
echo ""
echo "下一步："
echo "1. 如果是整合包，将模组文件复制到: $MC_DIR/mods/"
echo "2. 启动服务器: sudo systemctl start mc-server"
echo "3. 查看状态: sudo systemctl status mc-server"
echo "4. 查看日志: sudo journalctl -u mc-server -f"
echo ""
echo "备份文件: $BACKUP_FILE"
echo ""

