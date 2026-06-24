#!/bin/bash

# 获取当前脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 检查是否已存在 crontab 条目
if crontab -l 2>/dev/null | grep -q "$SCRIPT_DIR/backup.sh"; then
    echo "定时备份已存在，无需重复设置"
    exit 0
fi

# 添加定时备份任务（每天凌晨 2 点）
(crontab -l 2>/dev/null; echo "0 2 * * * cd $SCRIPT_DIR && ./backup.sh >> ./backups/backup.log 2>&1") | crontab -

echo "✅ 定时备份已设置"
echo "备份时间: 每天凌晨 2:00"
echo "备份日志: $SCRIPT_DIR/backups/backup.log"
echo ""
echo "查看定时任务:"
crontab -l | grep backup