#!/bin/bash

# 检查参数
if [ -z "$1" ]; then
    echo "使用方法: ./restore.sh <备份日期>"
    echo "例如: ./restore.sh 20260610_175000"
    echo ""
    echo "可用的备份文件:"
    ls -1 ./backups/*.sql 2>/dev/null | sed 's/.*n8n_db_//' | sed 's/.sql//'
    exit 1
fi

BACKUP_DATE=$1
BACKUP_DIR="./backups"

# 检查备份文件是否存在
if [ ! -f "$BACKUP_DIR/n8n_db_$BACKUP_DATE.sql" ]; then
    echo "❌ 备份文件不存在: $BACKUP_DIR/n8n_db_$BACKUP_DATE.sql"
    exit 1
fi

echo "开始恢复 n8n 数据..."
echo "备份日期: $BACKUP_DATE"

# 1. 停止 n8n 服务
echo "停止 n8n 服务..."
docker compose stop n8n

# 2. 恢复 PostgreSQL 数据库
echo "恢复 PostgreSQL 数据库..."
docker compose exec -T postgres psql -U n8n -d n8n < "$BACKUP_DIR/n8n_db_$BACKUP_DATE.sql"

if [ $? -eq 0 ]; then
    echo "✅ PostgreSQL 恢复成功"
else
    echo "❌ PostgreSQL 恢复失败"
    exit 1
fi

# 3. 恢复 n8n 数据卷（如果存在）
if [ -f "$BACKUP_DIR/n8n_data_$BACKUP_DATE.tar.gz" ]; then
    echo "恢复 n8n 数据卷..."
    docker run --rm -v n8n_n8n_data:/target -v $(pwd)/$BACKUP_DIR:/backup alpine tar xzf /backup/n8n_data_$BACKUP_DATE.tar.gz -C /target

    if [ $? -eq 0 ]; then
        echo "✅ n8n 数据恢复成功"
    else
        echo "❌ n8n 数据恢复失败"
        exit 1
    fi
fi

# 4. 恢复本地文件（如果存在）
if [ -f "$BACKUP_DIR/local_files_$BACKUP_DATE.tar.gz" ]; then
    echo "恢复本地文件..."
    tar xzf "$BACKUP_DIR/local_files_$BACKUP_DATE.tar.gz"
    echo "✅ 本地文件恢复成功"
fi

# 5. 重启 n8n 服务
echo "重启 n8n 服务..."
docker compose start n8n

echo ""
echo "恢复完成！"
echo "请访问 http://localhost:5678 验证数据"