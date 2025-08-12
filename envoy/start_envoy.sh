#!/bin/bash

# 設定檔案描述符限制
ulimit -n "${ENVOY_MAX_OPEN_FILES:-102400}"

# 設定 inotify 監視器限制 (需要 root 權限，在 Docker 中可能不可用)
# sysctl fs.inotify.max_user_watches="${ENVOY_MAX_INOTIFY_WATCHES:-524288}"

# 啟動 Envoy
exec /usr/local/bin/envoy \
 -c /etc/envoy/envoy.yaml \
 --restart-epoch "${RESTART_EPOCH:-0}" \
 --service-node "${SERVICE_NODE:-envoy-node}" \
 --service-zone "${SERVICE_ZONE:-unknown}"