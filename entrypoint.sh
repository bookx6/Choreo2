#!/bin/sh

# 定义 UUID 及 伪装路径,请自行修改.(注意:伪装路径以 / 符号开始,为避免不必要的麻烦,请不要使用特殊符号.)
UUID=${UUID:-'6F3617CC-3769-880D-CF70-EF2A88704C97'}
WSPATH=${WSPATH:-'choreo'}

# 生成配置文件，并经过 base64 加密
echo "{
    \"log\":{
        \"access\":\"/dev/null\",
        \"error\":\"/dev/null\",
        \"loglevel\":\"none\"
    },
    \"inbounds\":[
        {
            \"port\":8443,
            \"protocol\":\"vless\",
            \"settings\":{
                \"clients\":[
                    {
                        \"id\":\"${UUID}\",
                        \"flow\":\"xtls-rprx-vision\"
                    }
                ],
                \"decryption\":\"none\",
                \"fallbacks\":[
                    {
                        \"dest\":3001
                    },
                    {
                        \"path\":\"/${WSPATH}-vless\",
                        \"dest\":3002
                    },
                    {
                        \"path\":\"/${WSPATH}-vmess\",
                        \"dest\":3003
                    },
                    {
                        \"path\":\"/${WSPATH}-trojan\",
                        \"dest\":3004
                    },
                    {
                        \"path\":\"/${WSPATH}-shadowsocks\",
                        \"dest\":3005
                    }
                ]
            },
            \"streamSettings\":{
                \"network\":\"tcp\"
            }
        },
        {
            \"port\":3001,
            \"listen\":\"127.0.0.1\",
            \"protocol\":\"vless\",
            \"settings\":{
                \"clients\":[
                    {
                        \"id\":\"${UUID}\"
                    }
                ],
                \"decryption\":\"none\"
            },
            \"streamSettings\":{
                \"network\":\"ws\",
                \"security\":\"none\"
            }
        },
        {
            \"port\":3002,
            \"listen\":\"127.0.0.1\",
            \"protocol\":\"vless\",
            \"settings\":{
                \"clients\":[
                    {
                        \"id\":\"${UUID}\",
                        \"level\":0
                    }
                ],
                \"decryption\":\"none\"
            },
            \"streamSettings\":{
                \"network\":\"ws\",
                \"security\":\"none\",
                \"wsSettings\":{
                    \"path\":\"/${WSPATH}-vless\"
                }
            },
            \"sniffing\":{
                \"enabled\":true,
                \"destOverride\":[
                    \"http\",
                    \"tls\"
                ],
                \"metadataOnly\":false
            }
        },
        {
            \"port\":3003,
            \"listen\":\"127.0.0.1\",
            \"protocol\":\"vmess\",
            \"settings\":{
                \"clients\":[
                    {
                        \"id\":\"${UUID}\",
                        \"alterId\":0
                    }
                ]
            },
            \"streamSettings\":{
                \"network\":\"ws\",
                \"wsSettings\":{
                    \"path\":\"/${WSPATH}-vmess\"
                }
            },
            \"sniffing\":{
                \"enabled\":true,
                \"destOverride\":[
                    \"http\",
                    \"tls\"
                ],
                \"metadataOnly\":false
            }
        },
        {
            \"port\":3004,
            \"listen\":\"127.0.0.1\",
            \"protocol\":\"trojan\",
            \"settings\":{
                \"clients\":[
                    {
                        \"password\":\"${UUID}\"
                    }
                ]
            },
            \"streamSettings\":{
                \"network\":\"ws\",
                \"security\":\"none\",
                \"wsSettings\":{
                    \"path\":\"/${WSPATH}-trojan\"
                }
            },
            \"sniffing\":{
                \"enabled\":true,
                \"destOverride\":[
                    \"http\",
                    \"tls\"
                ],
                \"metadataOnly\":false
            }
        },
        {
            \"port\":3005,
            \"listen\":\"127.0.0.1\",
            \"protocol\":\"shadowsocks\",
            \"settings\":{
                \"clients\":[
                    {
                        \"method\":\"chacha20-ietf-poly1305\",
                        \"password\":\"${UUID}\"
                    }
                ],
                \"decryption\":\"none\"
            },
            \"streamSettings\":{
                \"network\":\"ws\",
                \"wsSettings\":{
                    \"path\":\"/${WSPATH}-shadowsocks\"
                }
            },
            \"sniffing\":{
                \"enabled\":true,
                \"destOverride\":[
                    \"http\",
                    \"tls\"
                ],
                \"metadataOnly\":false
            }
        }
    ],
    \"dns\":{
        \"servers\":[
            \"https+local://8.8.8.8/dns-query\"
        ]
    },
    \"outbounds\":[
        {
            \"protocol\":\"freedom\"
        },
        {
            \"tag\":\"WARP\",
            \"protocol\":\"wireguard\",
            \"settings\":{
                \"secretKey\":\"cKE7LmCF61IhqqABGhvJ44jWXp8fKymcMAEVAzbDF2k=\",
                \"address\":[
                    \"172.16.0.2/32\",
                    \"fd01:5ca1:ab1e:823e:e094:eb1c:ff87:1fab/128\"
                ],
                \"peers\":[
                    {
                        \"publicKey\":\"bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=\",
                        \"endpoint\":\"162.159.193.10:2408\"
                    }
                ]
            }
        }
    ],
    \"routing\":{
        \"domainStrategy\":\"AsIs\",
        \"rules\":[
            {
                \"type\":\"field\",
                \"domain\":[
                    \"domain:openai.com\",
                    \"domain:ai.com\"
                ],
                \"outboundTag\":\"WARP\"
            }
        ]
    }
}" | base64 > /tmp/config.base64

# 如果有设置哪吒探针三个变量,会安装。如果不填或者不全,则不会安装
if [ -n "${NEZHA_SERVER}" ] && [ -n "${NEZHA_PORT}" ] && [ -n "${NEZHA_KEY}" ]; then
  TLS=${NEZHA_TLS:+'--tls'}
  wget -O /tmp/nezha-agent.zip https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_$(uname -m | sed "s#x86_64#amd64#; s#aarch64#arm64#").zip
  unzip /tmp/nezha-agent.zip -d /tmp
  chmod +x /tmp/nezha-agent
  rm -f /tmp/nezha-agent.zip
  nohup /tmp/nezha-agent -s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${TLS} 2>&1 &
fi

# 不输出日志运行 APP
APP=$(ls [A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9])
base64 -d /tmp/config.base64 | nohup ./${APP} run >/dev/null 2>&1 &

# 保持脚本不结束
tail -f /dev/null
