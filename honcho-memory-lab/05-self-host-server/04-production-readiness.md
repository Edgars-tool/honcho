# 04 — Production Readiness

> 上線前確認清單

---

## Production Checklist

### 安全性

```
[ ] AUTH_USE_AUTH=true
[ ] AUTH_JWT_SECRET 已設定（用 scripts/generate_jwt_secret.py 生成）
[ ] .env 不在 git repo 中
[ ] DB / Redis port 綁定 127.0.0.1
[ ] HTTPS reverse proxy 設定完成
[ ] Firewall 只開放必要 port
```

### 可靠性

```
[ ] docker compose restart policy = unless-stopped（Docker Compose 預設）
[ ] 備份排程設定完成
[ ] 監控設定完成（至少有 health check cron）
[ ] Log rotation 設定（Docker 預設限制 log 大小）
```

### 效能

```
[ ] DERIVER_WORKERS 設定合理（高負載建議 2-4）
[ ] Redis caching 開啟（CACHE_ENABLED=true）
[ ] DB connection pool 調整（DB_POOL_SIZE）
```

### LLM 設定

```
[ ] 所有使用到的 LLM provider API key 都已設定
[ ] 確認模型支援 tool calling（Deriver / Dialectic / Dreamer 必要）
[ ] （若用非 Anthropic provider）THINKING_BUDGET_TOKENS=0
```

---

## 健康監控（最小版）

```powershell
# 建立每 5 分鐘執行一次的健康監控
# 放入 Windows 工作排程器或 cron

$result = try {
    Invoke-RestMethod -Uri "http://localhost:8000/health" -TimeoutSec 10
    "OK"
} catch {
    "FAIL: $_"
}

if ($result -ne "OK") {
    Write-Host "[ALERT] Honcho health check failed: $result"
    # 可以在此加入通知（Email、Slack webhook 等）
}
```

---

## Log Rotation（Docker 設定）

在 `docker-compose.yml` 加入 log 限制：

```yaml
services:
  api:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
  deriver:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

---

## 效能調整建議

| 參數 | 預設 | 建議（生產） | 說明 |
|------|------|-------------|------|
| `DERIVER_WORKERS` | 1 | 2-4 | 記憶處理吞吐量 |
| `CACHE_ENABLED` | false | true | Redis caching |
| `DB_POOL_SIZE` | 10 | 20 | DB 連線池 |
| `DB_MAX_OVERFLOW` | 20 | 30 | 超出 pool 時的最大連線 |

---

## 不適合 Production 的情境

- 沒有備份策略
- Auth 未開啟但對外公開
- 沒有 HTTPS
- 單 Deriver worker 但高訊息量（queue 積壓）
- 沒有監控（掛了不知道）
