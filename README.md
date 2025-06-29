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
git clone https://github.com/mymindwas/Nexus-.git
```
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

## VPS内存过小可以自行添加虚拟内存

### 给脚本添加执行权限
chmod +x setup_swap.sh

### 检查当前swap状态
sudo ./setup_swap.sh status

### 自动创建swap（推荐）
sudo ./setup_swap.sh create

### 创建指定大小的swap（例如2GB）
sudo ./setup_swap.sh create 2048

### 优化swap参数
sudo ./setup_swap.sh optimize

### 删除swap文件
sudo ./setup_swap.sh remove

### 查看帮助
./setup_swap.sh help
