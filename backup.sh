#!/bin/bash

# 备份目录
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p $BACKUP_DIR

echo "开始备份 n8n 数据..."

# 1. 备份 PostgreSQL 数据库
echo "备份 PostgreSQL 数据库..."
docker compose exec -T postgres pg_dump -U n8n n8n > "$BACKUP_DIR/n8n_db_$DATE.sql"

if [ $? -eq 0 ]; then
    echo "✅ PostgreSQL 备份成功: $BACKUP_DIR/n8n_db_$DATE.sql"
else
    echo "❌ PostgreSQL 备份失败"
    exit 1
fi

# 2. 备份 n8n 数据卷
echo "备份 n8n 数据卷..."
docker run --rm -v n8n_n8n_data:/source -v $(pwd)/$BACKUP_DIR:/backup alpine tar czf /backup/n8n_data_$DATE.tar.gz -C /source .

if [ $? -eq 0 ]; then
    echo "✅ n8n 数据备份成功: $BACKUP_DIR/n8n_data_$DATE.tar.gz"
else
    echo "❌ n8n 数据备份失败"
    exit 1
fi

# 3. 备份本地文件
if [ -d "./local-files" ]; then
    echo "备份本地文件..."
    tar czf "$BACKUP_DIR/local_files_$DATE.tar.gz" ./local-files
    echo "✅ 本地文件备份成功: $BACKUP_DIR/local_files_$DATE.tar.gz"
fi

# 4. 删除 30 天前的备份
echo "清理旧备份..."
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo ""
echo "备份完成！"
echo "备份目录: $BACKUP_DIR"
echo "备份文件列表:"
ls -lh $BACKUP_DIR/*$DATE*