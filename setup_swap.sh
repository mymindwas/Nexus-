#!/bin/bash

# VPS虚拟内存设置脚本
# 用于在Linux VPS上设置和管理swap空间

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        log_info "请使用: sudo $0"
        exit 1
    fi
}

# 检查当前swap状态
check_swap_status() {
    log_info "检查当前swap状态..."
    echo "----------------------------------------"
    free -h
    echo "----------------------------------------"
    
    # 检查swap文件
    if swapon --show | grep -q "/swapfile"; then
        log_success "发现swap文件: /swapfile"
        swapon --show
    else
        log_warning "未发现swap文件"
    fi
    
    # 检查swap分区
    if swapon --show | grep -q "/dev/"; then
        log_success "发现swap分区"
        swapon --show
    fi
}

# 计算推荐的swap大小
calculate_swap_size() {
    local total_ram=$(free -m | awk '/^Mem:/{print $2}')
    local swap_size=0
    
    if [ $total_ram -lt 1024 ]; then
        # 小于1GB RAM，swap = RAM * 2
        swap_size=$((total_ram * 2))
    elif [ $total_ram -lt 2048 ]; then
        # 1-2GB RAM，swap = RAM * 1.5
        swap_size=$((total_ram * 3 / 2))
    elif [ $total_ram -lt 4096 ]; then
        # 2-4GB RAM，swap = RAM
        swap_size=$total_ram
    else
        # 大于4GB RAM，swap = 4GB
        swap_size=4096
    fi
    
    echo $swap_size
}

# 创建swap文件
create_swap_file() {
    local size_mb=$1
    local swapfile="/swapfile"
    
    log_info "创建 ${size_mb}MB 的swap文件..."
    
    # 检查是否已存在swap文件
    if [ -f "$swapfile" ]; then
        log_warning "swap文件已存在: $swapfile"
        read -p "是否要删除现有swap文件并重新创建? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "删除现有swap文件..."
            swapoff "$swapfile" 2>/dev/null || true
            rm -f "$swapfile"
        else
            log_info "跳过swap文件创建"
            return 0
        fi
    fi
    
    # 创建swap文件
    log_info "正在创建swap文件，这可能需要一些时间..."
    dd if=/dev/zero of="$swapfile" bs=1M count="$size_mb" status=progress
    
    # 设置权限
    chmod 600 "$swapfile"
    
    # 格式化为swap
    mkswap "$swapfile"
    
    # 启用swap
    swapon "$swapfile"
    
    log_success "swap文件创建并启用成功"
}

# 配置swap开机自启
configure_swap_persistence() {
    local swapfile="/swapfile"
    
    log_info "配置swap开机自启..."
    
    # 检查是否已在fstab中
    if grep -q "$swapfile" /etc/fstab; then
        log_warning "swap文件已在/etc/fstab中配置"
    else
        # 添加到fstab
        echo "$swapfile none swap sw 0 0" >> /etc/fstab
        log_success "swap文件已添加到/etc/fstab"
    fi
}

# 优化swap使用
optimize_swap() {
    log_info "优化swap使用参数..."
    
    # 设置swappiness (控制使用swap的倾向性，0-100)
    # 默认通常是60，对于VPS建议设置为10-30
    local swappiness=20
    
    # 临时设置
    sysctl vm.swappiness="$swappiness"
    
    # 永久设置
    if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
        echo "vm.swappiness = $swappiness" >> /etc/sysctl.conf
        log_success "swappiness已设置为 $swappiness"
    else
        log_warning "swappiness已在/etc/sysctl.conf中配置"
    fi
    
    # 设置vfs_cache_pressure (控制缓存回收倾向性)
    local cache_pressure=50
    sysctl vm.vfs_cache_pressure="$cache_pressure"
    
    if ! grep -q "vm.vfs_cache_pressure" /etc/sysctl.conf; then
        echo "vm.vfs_cache_pressure = $cache_pressure" >> /etc/sysctl.conf
        log_success "vfs_cache_pressure已设置为 $cache_pressure"
    fi
}

# 删除swap文件
remove_swap() {
    local swapfile="/swapfile"
    
    log_warning "准备删除swap文件..."
    
    if [ -f "$swapfile" ]; then
        # 禁用swap
        swapoff "$swapfile"
        
        # 从fstab中移除
        sed -i '/\/swapfile/d' /etc/fstab
        
        # 删除文件
        rm -f "$swapfile"
        
        log_success "swap文件已删除"
    else
        log_warning "swap文件不存在"
    fi
}

# 显示帮助信息
show_help() {
    echo "VPS虚拟内存设置脚本"
    echo
    echo "用法: $0 [选项]"
    echo
    echo "选项:"
    echo "  status     - 检查当前swap状态"
    echo "  create     - 创建swap文件（自动计算大小）"
    echo "  create <MB> - 创建指定大小的swap文件"
    echo "  remove     - 删除swap文件"
    echo "  optimize   - 优化swap使用参数"
    echo "  help       - 显示此帮助信息"
    echo
    echo "示例:"
    echo "  sudo $0 status    # 检查状态"
    echo "  sudo $0 create    # 自动创建swap"
    echo "  sudo $0 create 2048  # 创建2GB swap"
    echo "  sudo $0 remove   # 删除swap"
}

# 主函数
main() {
    case "${1:-help}" in
        "status")
            check_swap_status
            ;;
        "create")
            check_root
            if [ -n "$2" ] && [[ "$2" =~ ^[0-9]+$ ]]; then
                size_mb=$2
                log_info "使用指定大小: ${size_mb}MB"
            else
                size_mb=$(calculate_swap_size)
                log_info "自动计算大小: ${size_mb}MB"
            fi
            create_swap_file "$size_mb"
            configure_swap_persistence
            optimize_swap
            check_swap_status
            ;;
        "remove")
            check_root
            remove_swap
            check_swap_status
            ;;
        "optimize")
            check_root
            optimize_swap
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# 运行主函数
main "$@" 