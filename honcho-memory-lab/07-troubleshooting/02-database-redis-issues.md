# 02 — Database / Redis 問題

---

## PostgreSQL

### 連線失敗

**症狀**：

```
sqlalchemy.exc.OperationalError: (psycopg.OperationalError) connection refused
```

**診斷**：

```powershell
# 確認 DB 容器狀態
docker compose ps database

# 測試連線
docker compose exec database psql -U honcho -d honcho -c "SELECT 1;"
```

**常見原因**：

| 原因 | 修復 |
|------|------|
| DB 容器未啟動 | `docker compose start database` |
| URI 格式錯誤 | 確認 `postgresql+psycopg://` 前綴 |
| 密碼錯誤 | 確認 .env 中 `POSTGRES_PASSWORD` 與 URI 一致 |
| host 錯誤 | 容器內應用用 `database`（service name），不是 `localhost` |

---

### Migration 問題

**查看 migration 狀態**：

```powershell
docker compose exec api alembic current
docker compose exec api alembic history
```

**重跑 migration**：

```powershell
docker compose exec api alembic upgrade head
```

**回滾一版**：

```powershell
docker compose exec api alembic downgrade -1
```

---

### 常用 DB 查詢（診斷用）

```powershell
# 進入 psql
docker compose exec database psql -U honcho -d honcho

# 查各資料表筆數
SELECT schemaname, tablename, n_live_tup FROM pg_stat_user_tables ORDER BY n_live_tup DESC;

# 查 queue 狀態
SELECT status, COUNT(*) FROM queue_items GROUP BY status;

# 查最近訊息
SELECT id, created_at, content FROM messages ORDER BY created_at DESC LIMIT 10;

# 退出
\q
```

---

### Disk 空間不足

**症狀**：DB write 失敗，log 含 `no space left on device`。

**診斷**：

```powershell
# Docker volumes 使用空間
docker system df -v

# 清理未使用的 images/volumes
docker system prune -f
```

---

## Redis

### Redis 連線失敗

**症狀**：

```
redis.exceptions.ConnectionError: Error 111 connecting to redis:6379
```

**診斷**：

```powershell
# 確認 Redis 容器
docker compose ps redis

# 測試連線
docker compose exec redis redis-cli ping
# 應回 PONG
```

**修復**：

```powershell
docker compose restart redis
```

---

### Redis 記憶體不足

**症狀**：`OOM command not allowed when used memory > 'maxmemory'`

**在 .env 設定**（或 docker-compose.yml command）：

```
# docker-compose.yml
redis:
  image: redis:alpine
  command: redis-server --maxmemory 512mb --maxmemory-policy allkeys-lru
```

---

### 清除 Redis queue

```powershell
docker compose exec redis redis-cli FLUSHDB
```

⚠️ 這會清除所有待處理的 queue items。僅在緊急情況使用。
