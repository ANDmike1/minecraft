# minecraft
阿里云服务器 minecraft 配置

## 目录

1. [服务器部署](#服务器部署)
2. [配置文件详解](#配置文件详解)
3. [性能优化](#性能优化)
4. [版本管理](#版本管理)
5. [问题排查](#问题排查)
6. [系统优化](#系统优化)
7. [安全配置](#安全配置)
8. [日常维护](#日常维护)

---

## 服务器部署

### 系统要求

- **云服务商**: 阿里云
- **系统**: Ubuntu 22.04
- **推荐配置**: 2核2GB内存（最低配置）
- **Java版本**: OpenJDK 17

### 快速部署步骤

#### 1. 连接到服务器

```bash
ssh root@your-server-ip
# 或使用你的用户名
ssh username@your-server-ip
```

#### 2. 上传安装脚本

将以下文件上传到服务器：
- `install_mc_server.sh` - 主安装脚本
- `setup_firewall.sh` - 防火墙配置
- `setup_systemd.sh` - 系统服务配置
- `start_mc_server.sh` - 启动脚本

或者直接在服务器上创建这些文件。

#### 3. 执行安装

```bash
# 给脚本添加执行权限
chmod +x *.sh

# 运行安装脚本
sudo bash install_mc_server.sh
```

安装脚本会自动完成：
- 系统更新
- 安装Java 17
- 创建Minecraft用户和目录
- 下载最新版Minecraft服务器
- 配置服务器参数（针对2GB内存优化）
- 创建启动/停止脚本

#### 4. 配置防火墙

```bash
sudo bash setup_firewall.sh
```

#### 5. 配置systemd服务（推荐）

```bash
sudo bash setup_systemd.sh
```

#### 6. 配置阿里云安全组

在阿里云控制台：
1. 进入ECS实例管理
2. 点击"安全组"（或"网络与安全" > "安全组"）
3. 确保在"入方向"标签页
4. 点击 **"+ 添加入方向规则"** 按钮
5. 填写规则配置：
   - **授权策略**: 允许
   - **优先级**: 100（默认）
   - **协议类型**: 自定义TCP
   - **端口范围**: 25565/25565
   - **访问来源**: IPv4地址段访问
   - **授权对象**: 
     - 公开访问: `0.0.0.0/0`（允许所有人）
     - 限制访问: `你的IP/32`（仅允许特定IP）
   - **描述**: Minecraft Server（可选）
6. 点击"保存"

#### 7. 初始化服务器

如果 `eula.txt` 不存在，需要初始化：

```bash
# 使用初始化脚本（推荐）
chmod +x 初始化MC服务器.sh
sudo bash 初始化MC服务器.sh

# 或手动初始化
cd /opt/minecraft
sudo -u minecraft java -Xmx1024M -Xms512M -jar server.jar nogui
# 等待几秒后按 Ctrl+C 停止
sudo sed -i 's/eula=false/eula=true/' /opt/minecraft/eula.txt
```

#### 8. 启动服务器

**方式一：使用systemd（推荐）**

```bash
# 启动服务器
sudo systemctl start mc-server

# 查看状态
sudo systemctl status mc-server

# 查看日志
sudo journalctl -u mc-server -f

# 设置开机自启（已自动启用）
sudo systemctl enable mc-server
```

**方式二：使用screen手动启动**

```bash
sudo bash start_mc_server.sh
# 或
sudo -u minecraft screen -S minecraft /opt/minecraft/start.sh
```

---

## 配置文件详解

### server.properties 位置

```
/opt/minecraft/server.properties
```

### 编辑配置文件

```bash
# 使用nano编辑器（推荐新手）
sudo nano /opt/minecraft/server.properties

# 或使用vim编辑器
sudo vim /opt/minecraft/server.properties

# 编辑后需要重启服务器才能生效
sudo systemctl restart mc-server
```

### 关键配置项说明

#### 网络与连接设置

- **server-port=25565**: 服务器监听端口（Minecraft标准端口）
- **server-ip=**: 服务器绑定IP（留空表示监听所有网络接口）
- **online-mode=true**: 是否启用正版验证
  - `true`: 只允许正版玩家（推荐，更安全）
  - `false`: 允许离线模式玩家（适合朋友间游玩）
- **network-compression-threshold=256**: 网络压缩阈值（字节）

#### 游戏规则设置

- **gamemode=survival**: 默认游戏模式（survival/creative/adventure/spectator）
- **force-gamemode=false**: 是否强制玩家使用默认游戏模式
- **difficulty=normal**: 游戏难度（peaceful/easy/normal/hard）
- **hardcore=false**: 是否启用极限模式
- **pvp=true**: 是否允许玩家间战斗

#### 玩家设置

- **max-players=10**: 最大玩家数
  - ⚠️ **重要**: 每个玩家约消耗100-200MB内存
  - 2GB服务器建议: 8-10人
  - 4GB服务器建议: 15-20人
  - 8GB+服务器建议: 20+人
- **player-idle-timeout=30**: 玩家空闲超时（分钟），0表示不踢出
- **spawn-protection=16**: 出生点保护半径（方块数）

#### 性能优化设置（⚠️ 最重要！）

- **view-distance=8**: 视距（区块数）
  - ⚠️ **最关键的性能参数**
  - 控制玩家能看到和加载的区块数量
  - 每个玩家加载的区块数 = view-distance²
  - 视距8 = 每个玩家约64个区块
  - 视距10 = 每个玩家约100个区块
  - **2GB服务器推荐: 6-8**
  - **4GB服务器推荐: 8-10**
  - **8GB+服务器推荐: 10-12**
  
- **simulation-distance=6**: 模拟距离（区块数）
  - 控制实体（生物、掉落物等）的更新范围
  - 比view-distance更影响性能
  - **2GB服务器推荐: 4-6**
  - **4GB服务器推荐: 6-8**
  - **8GB+服务器推荐: 8-10**
  - 建议设置为view-distance的75%左右

- **entity-broadcast-range-percentage=100**: 实体广播范围百分比
  - 2GB服务器可以降低到75或50，减少网络流量

#### 世界生成设置

- **level-name=world**: 世界文件夹名称（对应 `/opt/minecraft/world/` 目录）
- **level-seed=**: 世界种子（留空生成随机世界）
- **level-type=minecraft:normal**: 世界类型（normal/flat/large_biomes/amplified）
- **generate-structures=true**: 是否生成结构（村庄、要塞等）

#### 功能设置

- **enable-command-block=false**: 是否启用命令方块
- **enable-rcon=false**: 是否启用RCON（远程控制）
  - 如果启用，需要设置 `rcon.port`（建议25575）和强密码
- **enable-query=false**: 是否启用查询功能

#### 消息设置

- **motd=Minecraft Server on Ubuntu**: 服务器描述（MOTD）
  - 支持颜色代码（§符号）
  - 示例: `§6我的Minecraft服务器`

### 2GB服务器优化配置示例

```properties
# 网络设置
server-port=25565
server-ip=
network-compression-threshold=256
online-mode=true

# 游戏规则
gamemode=survival
force-gamemode=false
difficulty=normal
pvp=true

# 玩家设置（重要！）
max-players=8
player-idle-timeout=30
spawn-protection=16

# 世界生成
level-name=world
level-seed=
level-type=minecraft:normal
generate-structures=true

# 性能优化（关键！）
view-distance=6
simulation-distance=4
max-tick-time=60000
entity-broadcast-range-percentage=75

# 功能设置
enable-command-block=false
enable-query=false
enable-rcon=false

# 消息设置
motd=我的Minecraft服务器
enable-status=true
```

---

## 性能优化

### 内存配置

针对2GB内存服务器，推荐配置：

#### systemd服务内存配置

编辑 `/etc/systemd/system/mc-server.service`：

```bash
sudo nano /etc/systemd/system/mc-server.service
```

找到 `ExecStart` 行，内存配置建议：

- **2GB服务器推荐**: `-Xmx1024M -Xms1024M`
- **内存紧张时**: `-Xmx768M -Xms768M`
- **最低配置**: `-Xmx512M -Xms512M`（可能卡顿）

修改后：

```bash
# 重新加载systemd
sudo systemctl daemon-reload

# 重启服务器
sudo systemctl restart mc-server
```

#### 内存分配建议

- 系统预留: ~300-500MB
- Minecraft堆内存: 1024MB（2GB服务器）
- 使用G1垃圾收集器
- 优化的JVM参数

### 服务器配置优化

1. **降低视距**
   - `view-distance=6`（2GB服务器）
   - `simulation-distance=4`

2. **限制玩家数**
   - `max-players=8`（2GB服务器）

3. **启用空闲超时**
   - `player-idle-timeout=30`（自动踢出空闲玩家）

4. **降低实体广播范围**
   - `entity-broadcast-range-percentage=75`

5. **限制实体生成**（可选）
   - 可以关闭怪物或动物生成以节省资源

### 定期维护

```bash
# 设置定时重启（每天凌晨3点）
sudo crontab -e
# 添加：
0 3 * * * systemctl restart mc-server
```

---

## 版本管理

### 确定服务器版本

```bash
# 查看服务器版本
sudo journalctl -u mc-server | grep -i "Starting minecraft server version"

# 或查看日志文件
sudo tail -50 /opt/minecraft/logs/latest.log | grep -i version
```

### 客户端版本选择

**规则**: 客户端版本必须与服务器版本匹配

- ✅ **相同版本**: 完全匹配（推荐）
- ✅ **兼容版本**: 小版本差异可能兼容（不保证）
- ❌ **不同版本**: 版本差异太大无法连接

### 更换服务器版本

#### 步骤1：备份当前服务器

```bash
# 停止服务器
sudo systemctl stop mc-server

# 备份整个服务器目录
sudo tar -czf /opt/minecraft-backup-$(date +%Y%m%d).tar.gz /opt/minecraft

# 或只备份世界文件
sudo tar -czf /opt/world-backup-$(date +%Y%m%d).tar.gz /opt/minecraft/world
```

#### 步骤2：下载新版本

```bash
cd /opt/minecraft

# 备份旧版本
sudo -u minecraft mv server.jar server.jar.old

# 下载新版本（需要替换为新版本的下载链接）
sudo -u minecraft wget -O server.jar https://piston-data.mojang.com/v1/objects/[版本hash]/server.jar
```

#### 步骤3：首次运行新版本

```bash
cd /opt/minecraft
sudo -u minecraft java -Xmx1024M -Xms1024M -jar server.jar nogui

# 等待几秒后按 Ctrl+C 停止
```

#### 步骤4：接受EULA

```bash
sudo sed -i 's/eula=false/eula=true/' /opt/minecraft/eula.txt
```

#### 步骤5：启动服务器

```bash
sudo systemctl start mc-server
sudo systemctl status mc-server
```

### 添加整合包

#### Forge整合包

1. 下载Forge安装器
2. 运行安装器：`java -jar forge-installer.jar --installServer`
3. 修改systemd服务，将 `server.jar` 改为 `forge-[版本].jar`
4. 增加内存配置（Forge需要更多内存）
5. 创建 `mods/` 目录并添加模组

#### Fabric整合包

1. 下载Fabric安装器
2. 安装Fabric服务器
3. 创建启动脚本或修改systemd服务
4. 创建 `mods/` 目录并添加模组

详细步骤请参考 `更换版本和添加整合包指南.md`。

---

## 问题排查

### 内存不足问题

**症状**:
- `code=killed, status=9/KILL`
- 进程启动后几秒就被杀死
- OOM Killer自动杀死进程

**解决方案**:

1. **降低内存配置**

```bash
# 编辑systemd服务文件
sudo nano /etc/systemd/system/mc-server.service

# 将 -Xmx1536M -Xms1536M 改为 -Xmx1024M -Xms1024M
# 或更低：-Xmx768M -Xms768M

# 重新加载并重启
sudo systemctl daemon-reload
sudo systemctl restart mc-server
```

2. **优化server.properties**

```properties
max-players=8
view-distance=6
simulation-distance=4
player-idle-timeout=30
```

3. **检查系统内存**

```bash
# 查看内存使用
free -h

# 查看内存占用进程
ps aux --sort=-%mem | head -10

# 查看OOM Killer日志
dmesg | grep -i oom
sudo journalctl -k | grep -i oom
```

4. **添加Swap**（可选）

```bash
# 创建2GB swap文件
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 永久启用
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### 服务器无法启动

1. **检查Java是否安装**

```bash
java -version
```

2. **检查内存是否足够**

```bash
free -h
```

3. **查看日志**

```bash
# 查看systemd日志
sudo journalctl -u mc-server -n 50

# 查看Minecraft日志
sudo tail -50 /opt/minecraft/logs/latest.log
```

4. **检查文件权限**

```bash
ls -la /opt/minecraft/
sudo chown -R minecraft:minecraft /opt/minecraft
```

### 无法连接服务器

1. **检查服务器是否运行**

```bash
sudo systemctl status mc-server
```

2. **检查防火墙**

```bash
sudo ufw status
sudo ufw allow 25565/tcp
```

3. **检查阿里云安全组规则**

确保在阿里云控制台中已添加25565端口的入方向规则。

4. **检查端口是否监听**

```bash
sudo netstat -tlnp | grep 25565
```

5. **检查客户端版本**

确保客户端版本与服务器版本匹配。

### 服务器卡顿

1. **降低视距和模拟距离**
   - `view-distance=6`
   - `simulation-distance=4`

2. **减少最大玩家数**
   - `max-players=8`

3. **检查内存使用**

```bash
free -h
ps aux | grep java
```

4. **重启服务器**

```bash
sudo systemctl restart mc-server
```

### EULA未接受问题

```bash
# 检查eula.txt
cat /opt/minecraft/eula.txt

# 如果不存在或eula=false，接受EULA
sudo sed -i 's/eula=false/eula=true/' /opt/minecraft/eula.txt

# 或手动创建
sudo -u minecraft bash -c 'echo "eula=true" > /opt/minecraft/eula.txt'
```

### 版本不匹配问题

```bash
# 确定服务器版本
sudo journalctl -u mc-server | grep -i "Starting minecraft server version"

# 客户端需要安装相同版本
```

---

## 系统优化

### 关闭不必要的服务

运行优化脚本：

```bash
chmod +x 优化系统服务.sh
sudo bash 优化系统服务.sh
```

或手动关闭：

```bash
# 停止不必要的服务
sudo systemctl stop docker.service
sudo systemctl stop containerd.service
sudo systemctl stop snapd.service
sudo systemctl stop fwupd.service
sudo systemctl stop packagekit.service
sudo systemctl stop ModemManager.service
sudo systemctl stop tuned.service
sudo systemctl stop udisks2.service
sudo systemctl stop unattended-upgrades.service
sudo systemctl stop atd.service

# 禁用服务（防止开机自启）
sudo systemctl disable docker.service
sudo systemctl disable containerd.service
# ... 等等
```

**可安全关闭的服务**:
- docker.service
- containerd.service
- snapd.service
- fwupd.service
- packagekit.service
- ModemManager.service
- tuned.service
- udisks2.service
- unattended-upgrades.service
- atd.service

**总计可释放内存**: 约 300-600MB

**必须保留的服务**:
- ssh.service（⚠️ 必须保留，否则无法远程管理）
- systemd核心服务
- rsyslog.service
- cron.service
- chrony.service

### 验证优化效果

```bash
# 查看内存使用
free -h

# 查看运行的服务
systemctl list-units --type=service --state=running
```

---

## 安全配置

### 防火墙配置

```bash
# 查看防火墙状态
sudo ufw status

# 允许Minecraft端口
sudo ufw allow 25565/tcp

# 如果使用RCON
sudo ufw allow 25575/tcp

# 启用防火墙
sudo ufw enable
```

### 阿里云安全组配置

1. 进入阿里云控制台 > ECS实例 > 安全组
2. 点击"添加入方向规则"
3. 配置：
   - **授权策略**: 允许
   - **协议类型**: 自定义TCP
   - **端口范围**: 25565/25565
   - **访问来源**: 
     - 公开访问: `0.0.0.0/0`
     - 限制访问: `你的IP/32`（更安全）
   - **描述**: Minecraft Server

### 服务器安全建议

1. **使用强密码**: 如果启用rcon，使用强密码
2. **启用正版验证**: `online-mode=true`
3. **定期更新**: 保持系统和Java更新
4. **限制访问**: 在安全组中限制IP访问（如果可能）
5. **监控日志**: 定期检查服务器日志
6. **备份数据**: 定期备份世界文件

---

## 日常维护

### 服务器管理命令

#### 启动/停止/重启

```bash
# 启动服务器
sudo systemctl start mc-server

# 停止服务器
sudo systemctl stop mc-server

# 重启服务器
sudo systemctl restart mc-server

# 查看状态
sudo systemctl status mc-server

# 查看日志
sudo journalctl -u mc-server -f
```

#### 查看服务器控制台

```bash
# 如果使用systemd
sudo journalctl -u mc-server -f

# 如果使用screen
screen -r minecraft
```

#### 发送命令到服务器

如果使用screen：

```bash
screen -S minecraft -X stuff "say 服务器消息$(printf \\r)"
```

如果使用systemd，需要通过rcon或直接编辑world文件。

### 备份服务器

#### 手动备份

```bash
# 备份整个服务器目录
sudo tar -czf minecraft-backup-$(date +%Y%m%d).tar.gz /opt/minecraft

# 只备份世界文件
sudo tar -czf world-backup-$(date +%Y%m%d).tar.gz /opt/minecraft/world
```

#### 自动备份脚本

创建 `/opt/minecraft/backup.sh`：

```bash
#!/bin/bash
BACKUP_DIR="/opt/backups/minecraft"
mkdir -p $BACKUP_DIR
tar -czf $BACKUP_DIR/world-$(date +%Y%m%d-%H%M%S).tar.gz -C /opt/minecraft world
# 保留最近7天的备份
find $BACKUP_DIR -name "world-*.tar.gz" -mtime +7 -delete
```

添加到crontab：

```bash
sudo crontab -e
# 每6小时备份一次
0 */6 * * * /opt/minecraft/backup.sh
```

### 监控服务器

#### 监控内存使用

```bash
# 查看内存使用
free -h

# 查看Java进程内存
ps aux | grep java

# 使用htop（更好的监控工具）
sudo apt install -y htop
htop
```

#### 监控日志

```bash
# 实时查看日志
sudo journalctl -u mc-server -f

# 查看最新日志
sudo journalctl -u mc-server -n 100

# 查看Minecraft日志
sudo tail -f /opt/minecraft/logs/latest.log
```

### 文件位置

- **服务器目录**: `/opt/minecraft`
- **服务器用户**: `minecraft`
- **配置文件**: `/opt/minecraft/server.properties`
- **世界文件**: `/opt/minecraft/world/`
- **日志文件**: `/opt/minecraft/logs/`
- **systemd服务**: `/etc/systemd/system/mc-server.service`
- **启动脚本**: `/opt/minecraft/start.sh`
- **停止脚本**: `/opt/minecraft/stop.sh`

### 处理系统更新提示

如果执行安装脚本时看到"Daemons using outdated libraries"提示：

1. 按 **Tab** 键切换到 `<Ok>` 按钮
2. 按 **Enter** 确认
3. 系统会自动重启选中的服务

已更新的安装脚本已添加非交互式模式，可以自动处理这些提示。

---

## 快速参考

### 常用命令

```bash
# 启动服务器
sudo systemctl start mc-server

# 停止服务器
sudo systemctl stop mc-server

# 重启服务器
sudo systemctl restart mc-server

# 查看状态
sudo systemctl status mc-server

# 查看日志
sudo journalctl -u mc-server -f

# 编辑配置
sudo nano /opt/minecraft/server.properties

# 查看内存
free -h

# 查看Java进程
ps aux | grep java
```

### 2GB服务器推荐配置

```properties
# server.properties
max-players=8
view-distance=6
simulation-distance=4
player-idle-timeout=30
entity-broadcast-range-percentage=75
```

```bash
# systemd服务内存配置
-Xmx1024M -Xms1024M
```

### 故障排查流程

1. **服务器无法启动**
   - 检查Java: `java -version`
   - 检查内存: `free -h`
   - 查看日志: `sudo journalctl -u mc-server -n 50`

2. **无法连接服务器**
   - 检查服务状态: `sudo systemctl status mc-server`
   - 检查防火墙: `sudo ufw status`
   - 检查安全组: 阿里云控制台
   - 检查端口: `sudo netstat -tlnp | grep 25565`

3. **内存不足**
   - 降低内存配置: `-Xmx1024M` 或更低
   - 优化server.properties
   - 关闭不必要的服务
   - 检查内存使用: `free -h`

4. **服务器卡顿**
   - 降低视距和模拟距离
   - 减少最大玩家数
   - 检查内存使用
   - 重启服务器

---
**关键要点**:
- 2GB服务器推荐配置：`max-players=8`, `view-distance=6`, `simulation-distance=4`
- 内存配置：`-Xmx1024M -Xms1024M`
- 每次修改配置后需要重启服务器
- 定期备份世界文件
- 监控内存使用，避免OOM Killer


