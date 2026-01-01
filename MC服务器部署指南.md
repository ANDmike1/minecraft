# Minecraft服务器部署指南

## 服务器配置
- **云服务商**: 阿里云
- **系统**: Ubuntu 22.04
- **配置**: 2核2GB内存
- **Java版本**: OpenJDK 17

## 快速部署步骤

### 1. 连接到服务器
```bash
ssh root@your-server-ip
# 或使用你的用户名
ssh username@your-server-ip
```

### 2. 上传安装脚本
将以下文件上传到服务器：
- `install_mc_server.sh`
- `setup_firewall.sh`
- `setup_systemd.sh`
- `start_mc_server.sh`

或者直接在服务器上创建这些文件。

### 3. 执行安装
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

### 4. 配置防火墙
```bash
sudo bash setup_firewall.sh
```

### 5. 配置systemd服务（可选，推荐）
```bash
sudo bash setup_systemd.sh
```

### 6. 配置阿里云安全组
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

> 📖 **详细配置说明**: 查看 `阿里云安全组配置指南.md` 获取更详细的步骤和截图说明

### 7. 启动服务器

#### 方式一：使用systemd（推荐）
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

#### 方式二：使用screen手动启动
```bash
sudo bash start_mc_server.sh
# 或
sudo -u minecraft screen -S minecraft /opt/minecraft/start.sh
```

## 服务器管理

### 查看服务器控制台
```bash
# 如果使用screen
screen -r minecraft

# 如果使用systemd
sudo journalctl -u mc-server -f
```

### 停止服务器
```bash
# 方式一：systemd
sudo systemctl stop mc-server

# 方式二：screen
screen -S minecraft -X stuff "stop$(printf \\r)"
# 或使用停止脚本
sudo -u minecraft /opt/minecraft/stop.sh
```

### 重启服务器
```bash
sudo systemctl restart mc-server
```

### 发送命令到服务器
```bash
# 如果使用systemd，需要通过rcon或直接编辑world文件
# 如果使用screen
screen -S minecraft -X stuff "say 服务器消息$(printf \\r)"
```

## 服务器配置优化

### 内存配置
针对2GB内存服务器，已优化为：
- 系统预留: ~512MB
- Minecraft堆内存: 1536MB
- 使用G1垃圾收集器
- 优化的JVM参数

### 修改服务器设置
编辑配置文件：
```bash
sudo nano /opt/minecraft/server.properties
```

常用配置项：
- `max-players=10`: 最大玩家数（2GB建议不超过10人）
- `view-distance=8`: 视距（降低可减少内存使用）
- `simulation-distance=6`: 模拟距离
- `difficulty=normal`: 难度
- `gamemode=survival`: 游戏模式
- `online-mode=true`: 正版验证（false为离线模式）

修改后重启服务器：
```bash
sudo systemctl restart mc-server
```

## 性能优化建议

### 1. 降低视距
在`server.properties`中：
```
view-distance=6
simulation-distance=4
```

### 2. 限制实体数量
在`server.properties`中：
```
spawn-monsters=true
spawn-animals=true
spawn-npcs=true
```

### 3. 定期重启
可以设置定时任务：
```bash
sudo crontab -e
# 添加：每天凌晨3点重启
0 3 * * * systemctl restart mc-server
```

### 4. 监控内存使用
```bash
# 查看内存使用
free -h

# 查看Java进程内存
ps aux | grep java
```

## 备份服务器

### 手动备份
```bash
# 备份整个服务器目录
sudo tar -czf minecraft-backup-$(date +%Y%m%d).tar.gz /opt/minecraft

# 只备份世界文件
sudo tar -czf world-backup-$(date +%Y%m%d).tar.gz /opt/minecraft/world
```

### 自动备份脚本
创建`/opt/minecraft/backup.sh`：
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

## 常见问题

### 1. 服务器无法启动
- 检查Java是否安装：`java -version`
- 检查内存是否足够：`free -h`
- 查看日志：`sudo journalctl -u mc-server -n 50`

### 2. 无法连接服务器
- 检查防火墙：`sudo ufw status`
- 检查阿里云安全组规则
- 检查服务器是否运行：`sudo systemctl status mc-server`
- 检查端口是否监听：`sudo netstat -tlnp | grep 25565`

### 3. 服务器卡顿
- 降低视距和模拟距离
- 减少最大玩家数
- 检查内存使用：`free -h`
- 重启服务器

### 4. 内存不足
- 降低`view-distance`
- 减少`max-players`
- 考虑升级服务器配置

## 文件位置

- 服务器目录: `/opt/minecraft`
- 服务器用户: `minecraft`
- 配置文件: `/opt/minecraft/server.properties`
- 世界文件: `/opt/minecraft/world/`
- 日志文件: `/opt/minecraft/logs/`
- systemd服务: `/etc/systemd/system/mc-server.service`

## 安全建议

1. **使用强密码**: 如果启用rcon，使用强密码
2. **定期更新**: 保持系统和Java更新
3. **备份数据**: 定期备份世界文件
4. **限制访问**: 在安全组中限制IP访问（如果可能）
5. **监控日志**: 定期检查服务器日志

## 联系与支持

如有问题，请检查：
1. 服务器日志：`sudo journalctl -u mc-server -f`
2. Minecraft日志：`/opt/minecraft/logs/latest.log`
3. 系统资源：`htop` 或 `top`

