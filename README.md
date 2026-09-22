# CodeArts OpenAI 兼容代理

把华为云 CodeArts [https://codearts.huaweicloud.com/] 的模型接口（盘古开源大模型2.0、GLM-5.2）包装成**标准 OpenAI Chat Completions API**。

底层走华为云 `SDK-HMAC-SHA256` 请求签名，AK/SK 存放在 `.env`。
## 新增免费层级模型，可使用benefit.py一键签到并通过server.py调用

## 使用方法

### 1. 安装依赖

```cmd
pip install -r requirements.txt
```

### 2. 配置 AK/SK

编辑 `.env`：

```ini
CODEARTS_AK=你的AccessKey
CODEARTS_SK=你的SecretKey
```
#### 如何获取AK/SK(Access Key/Secret Key)
进入 https://console.huaweicloud.com/iam/#/mine/accessKey ，登录后-->新增访问密钥 即可获取

**请勿泄露你的AK/SK，这具有华为云账号的最高访问权限**

### 3. 启动代理

```cmd
python server.py
```

默认监听：

```text
http://127.0.0.1:8787
```

### 4. 在各类工具中接入

把 OpenAI 兼容 Base URL 指向：

```text
http://127.0.0.1:8787/v1
```

- API Key：任意非空字符串（例如 `codearts`）
- 模型：`openpangu-2.0-pro`

支持的工具示例：OpenCode、Cline、Continue、LobeChat、Cherry Studio 等所有支持自定义 OpenAI 兼容端点的工具。

## Docker 部署

镜像基于 `python:3.12-slim-bookworm`（Debian 12），以非 root 用户运行，并已将监听地址改为
容器内 `0.0.0.0:8787`，因此端口映射可正常生效。

### 方式一：docker compose（推荐）

在项目目录下准备好 `.env`（内容同第 2 步），然后：

```bash
docker compose up -d
```

访问 `http://127.0.0.1:8787/v1`。默认只绑定宿主机回环地址，需要局域网访问时把
`docker-compose.yml` 中的 `"127.0.0.1:8787:8787"` 改为 `"8787:8787"`。

### 方式二：直接构建运行

```bash
docker build -t codearts2api:latest .

docker run -d --name codearts2api \
  --restart unless-stopped \
  -p 127.0.0.1:8787:8787 \
  -e CODEARTS_AK=你的AccessKey \
  -e CODEARTS_SK=你的SecretKey \
  codearts2api:latest
```

### 使用预构建的 x86_64 镜像

仓库通过 GitHub Actions 自动构建 `linux/amd64` 镜像并推送到 GHCR：

```bash
docker pull ghcr.io/qingtiandamowang/codearts2api:latest
```

> GHCR 的包默认是私有的。若拉取时报 `denied`，请在仓库的 `Packages` 页面把该包改为
> Public，或先执行 `docker login ghcr.io` 并使用具备 `read:packages` 权限的 Token。

### 每日自动签到

`benefit.py` 已打进镜像，可直接调用：

```bash
docker exec codearts2api python benefit.py claim
```

### 环境变量

| 变量 | 默认值 | 说明 |
|---|---|---|
| `CODEARTS_AK` | 无（必填） | 华为云 AccessKey |
| `CODEARTS_SK` | 无（必填） | 华为云 SecretKey |
| `CODEARTS_PROXY_HOST` | `127.0.0.1`（镜像内已设为 `0.0.0.0`） | 监听地址 |
| `CODEARTS_PROXY_PORT` | `8787` | 监听端口 |

## 本地测试

```cmd
python test_openai.py
```

## 接口说明

| 端点 | 说明 |
|---|---|
| `POST /v1/chat/completions` | OpenAI 格式聊天补全，支持 `stream` 流式 |
| `GET /v1/models` | 模型列表 |

## 代码结构

```text
codearts2api/
├── .env                    # AK/SK
├── server.py               # 主服务：签名 + 转发
├── benefit.py              # 免费额度签到 / 余额查询
├── requirements.txt        # Python 依赖
├── test_openai.py          # 本地测试脚本
├── models-cache.json       # 模型列表缓存
├── Dockerfile              # x86_64 镜像定义
├── docker-compose.yml      # 一键部署
├── .github/workflows/
│   └── docker-build.yml    # 自动构建 linux/amd64 镜像并推送 GHCR
└── README.md
```

## 说明

- 代理只做签名和转发，不修改模型行为。
- 每次调用会消耗华为云 CodeArts 套餐额度（token）。
- 仅绑定 `127.0.0.1`，不会对外网开放。
- 本项目及本项目作者与华为云平台及其附属公司无任何关系，且华为云平台中并未对本项目中调用方式明确提出允许，若造成封号/限流等任何因使用本工具造成的情况与项目作者无关。如果您使用该项目，则默认视为同意本Readme中所有说明

# 社区
感谢[LinuxDO](https://linux.do/)对本项目进行推广
