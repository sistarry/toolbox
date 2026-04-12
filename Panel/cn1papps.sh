#!/bin/bash
# 1Panel 本地应用更新（ghp.ci 加速 + 安全备份 + 1pctl 重启）

set -e

LOCAL_PATH="/opt/1panel/resource/apps/local"
ZIP_URL="https://v6.gh-proxy.org/https://github.com/okxlin/appstore/archive/refs/heads/localApps.zip"
BACKUP_DIR="/opt/1panel/resource/apps/backup_$(date +%Y%m%d_%H%M%S)"
ZIP_FILE="$LOCAL_PATH/localApps.zip"

echo "===== 1Panel 本地应用更新 ====="

# ==============================
# 检查并安装 unzip
# ==============================
check_unzip() {
    if ! command -v unzip >/dev/null 2>&1; then
        echo "⚠️ 未检测到 unzip，正在安装..."

        if [ -f /etc/debian_version ]; then
            apt update && apt install -y unzip
        elif [ -f /etc/redhat-release ]; then
            yum install -y unzip || dnf install -y unzip
        elif [ -f /etc/alpine-release ]; then
            apk add unzip
        else
            echo "❌ 无法识别系统，请手动安装 unzip"
            exit 1
        fi

        echo "✅ unzip 安装完成"
    fi
}

check_unzip


# ==============================
# 检查目录
# ==============================
if [ ! -d "$LOCAL_PATH" ]; then
    echo "❌ 未检测到 1Panel 本地应用目录：$LOCAL_PATH"
    exit 1
fi

# ==============================
# 备份
# ==============================
echo "📦 正在备份..."
mkdir -p "$BACKUP_DIR"
cp -rf "$LOCAL_PATH"/* "$BACKUP_DIR"/
echo "✅ 已备份到 $BACKUP_DIR"

# ==============================
# 下载
# ==============================
echo "⬇️ 正在下载最新 localApps.zip ..."

if ! wget -q -O "$ZIP_FILE" "$ZIP_URL"; then
    echo "❌ 下载失败，已终止更新"
    exit 1
fi


# ==============================
# 解压
# ==============================
echo "📂 正在解压..."

if ! unzip -o -q -d "$LOCAL_PATH" "$ZIP_FILE"; then
    echo "❌ 解压失败，已终止更新"
    rm -f "$ZIP_FILE"
    exit 1
fi


# ==============================
# 覆盖文件
# ==============================
echo "🔁 正在覆盖应用文件..."
cp -rf "$LOCAL_PATH/appstore-localApps/apps/"* "$LOCAL_PATH/"

# ==============================
# 清理
# ==============================
rm -rf "$LOCAL_PATH/appstore-localApps" "$ZIP_FILE"

# ==============================
# 重启 1Panel
# ==============================
echo "🔄 正在重启 1Panel..."

if command -v 1pctl >/dev/null 2>&1; then
    1pctl restart
    echo "✅ 1Panel 已成功重启"
else
    echo "⚠️ 未检测到 1pctl 命令，请手动执行：1pctl restart"
fi

echo "🎉 本地应用更新完成！"
echo "🗂 旧版本备份位置：$BACKUP_DIR"
