# syntax=docker/dockerfile:1
# CodeArts OpenAI 兼容代理 —— 官方镜像
# 纯 Python（Flask + requests），无任何需要本地编译的原生依赖，可稳定构建 linux/amd64。

# 固定 bookworm（Debian 12），与目标宿主机 Debian 12 / glibc 2.36 一致；
# 不写死代号的话 -slim 会随上游切换到 trixie，导致构建结果不可复现。
FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    TZ=Asia/Shanghai

WORKDIR /app

# 依赖单独一层：只改业务代码时不会触发重新安装依赖
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY server.py benefit.py test_openai.py models-cache.json ./

# 关键：容器内必须监听 0.0.0.0，否则宿主机的 -p 端口映射无法访问
ENV CODEARTS_PROXY_HOST=0.0.0.0 \
    CODEARTS_PROXY_PORT=8787

# 以非 root 运行；models-cache.json 在启动/刷新时会被回写，因此需要可写权限
RUN useradd --create-home --uid 10001 appuser \
 && chown -R appuser:appuser /app
USER appuser

EXPOSE 8787

# 仅做 TCP 探活，不请求 /v1/models，避免健康检查消耗上游额度。
# 启动时会先同步一次上游模型列表，期间不监听端口（实测阻塞 30-40s，
# 上游超时叠加时更久），故 start-period 放宽，避免被误判为 unhealthy。
HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
    CMD ["python", "-c", "import socket,sys; s=socket.socket(); s.settimeout(3); sys.exit(0 if s.connect_ex(('127.0.0.1',8787))==0 else 1)"]

# 上游文档以 Ctrl+C 停止服务，对应 SIGINT，容器停止时优雅退出
STOPSIGNAL SIGINT

CMD ["python", "server.py"]
