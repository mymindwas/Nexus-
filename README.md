# Nexus 节点设置脚本

## 简介
`setup_nexus_nodes.sh` 是一个自动化脚本，用于批量设置和启动 Nexus 网络节点。

## 功能
- 自动检查并安装 screen
- 安装 Nexus CLI
- 批量启动多个节点，每个节点在独立的 screen 会话中运行

## 使用方法

### 1. 给脚本执行权限
```bash
chmod +x setup_nexus_nodes.sh
```

### 2. 运行脚本
```bash
./setup_nexus_nodes.sh
```

## 节点管理

### 查看所有运行的节点
```bash
screen -ls
```

### 连接到特定节点
```bash
screen -r nexus_<node-id>
```

### 断开节点会话（不停止节点）
在 screen 会话中按 `Ctrl + A` 然后按 `D`

### 停止所有节点
```bash
screen -ls | grep nexus | awk '{print $1}' | xargs -I {} screen -S {} -X quit
```

## 注意事项
- 确保系统已安装 curl
- 脚本会自动安装 screen 和 Nexus CLI
- 每个节点在独立的 screen 会话中运行，名称为 `nexus_<node-id>`
- 如果节点已存在，脚本会跳过该节点 