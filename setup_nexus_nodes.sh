#!/bin/bash

# 日志函数
log() {
    echo "[Nexus Setup] $1"
}

# 检查并安装screen
check_and_install_screen() {
    if ! command -v screen &> /dev/null; then
        log "Screen not found, installing..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y screen
        elif command -v yum &> /dev/null; then
            sudo yum install -y screen
        else
            log "Could not install screen. Please install it manually."
            exit 1
        fi
    fi
}

# 安装Nexus CLI
install_nexus_cli() {
    log "Installing Nexus CLI..."
    curl https://cli.nexus.xyz/ | sh
    
    # 更新PATH
    export PATH="$HOME/.local/bin:$PATH"
    source ~/.bashrc
    
    # 创建配置目录
    mkdir -p ~/.nexus
}

# 启动节点
start_node() {
    local node_id=$1
    local screen_name="nexus_${node_id}"
    
    # 检查screen会话是否已存在
    if screen -list | grep -q "$screen_name"; then
        log "Screen session $screen_name already exists"
        return
    fi
    
    # 创建新的screen会话并启动节点
    log "Starting node $node_id in screen session $screen_name"
    screen -dmS "$screen_name" bash -c "nexus-network start --node-id $node_id"
}

# 主程序
main() {
    # 检查并安装screen
    check_and_install_screen
    
    # 安装Nexus CLI
    install_nexus_cli
    
    # 节点ID列表
    node_ids=(
5563861
5563864
5583839
5584038
5584039
5584040
5584041
5584042
5584044
5584045
5612974
5613121
5613173
5613177
5641150
5641153
5641154
5641155
    )
    
    # 为每个节点ID创建screen会话
    for node_id in "${node_ids[@]}"; do
        start_node "$node_id"
        # 添加短暂延迟，避免同时启动太多进程
        sleep 1
    done
    
    log "Setup completed. Use 'screen -ls' to list all sessions."
    log "To attach to a session, use 'screen -r nexus_<node-id>'"
}

# 运行主程序
main 