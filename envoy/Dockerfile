# 使用官方 Envoy 映像作為基礎
FROM envoyproxy/envoy:v1.33-latest

# 安裝 Python 和必要的套件
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    procps \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 建立工作目錄
WORKDIR /etc/envoy

# 複製 Python 熱重啟腳本
COPY hot-restarter.py /usr/local/bin/hot-restarter.py

# 複製啟動腳本
COPY start_envoy.sh /usr/local/bin/start_envoy.sh

# 設定執行權限
RUN chmod +x /usr/local/bin/hot-restarter.py && \
    chmod +x /usr/local/bin/start_envoy.sh

# 設定環境變數
ENV RESTART_EPOCH=0
ENV SERVICE_NODE=envoy-node
ENV SERVICE_ZONE=docker
ENV ENVOY_MAX_OPEN_FILES=102400

# 暴露 Envoy 使用的端口
EXPOSE 80 9901

# 預設啟動命令：使用 hot-restarter.py 來啟動 Envoy，支援熱重啟功能
# 設定檔和參數可以在 docker-compose 中覆蓋
CMD ["python3", "/usr/local/bin/hot-restarter.py", "/usr/local/bin/start_envoy.sh"]