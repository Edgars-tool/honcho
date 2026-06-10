# 01 — Docker Compose 細節

---

## 四個 Service 說明

```yaml
# docker-compose.yml 結構概覽（不是完整 compose 檔，只是說明用）

services:
  api:
    build: .          # 從 source 編譯，沒有 Docker Hub image
    ports:
      - "127.0.0.1:8000:8000"  # 只綁 localhost
    depends_on:
      - database
      - redis
    restart: unless-stopped

  deriver:
    build: .          # 同一個 image，不同 command
    command: python -m src.deriver
    depends_on:
      - database
      - redis
    restart: unless-stopped

  database:
    image: pgvector/pgvector:pg15  # 含 pgvector 的 PostgreSQL
    ports:
      - "127.0.0.1:5432:5432"  # 只綁 localhost
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:latest
    ports:
      - "127.0.0.1:6379:6379"  # 只綁 localhost
```

---

## 從 Source 編譯的原因

Honcho 沒有預建的 Docker Hub image。
這是因為每個部署可能有不同的設定和依賴版本。

第一次 build 需要 3-5 分鐘（下載依賴、編譯）。
之後的啟動不需要 rebuild，很快。

---

## Migration 自動執行

啟動時 API container 會自動執行 `alembic upgrade head`。
不需要手動跑 migration。

若看到 log 中有 `alembic` 相關訊息 → 正在執行 migration（正常）。

---

## 常用 Docker Compose 指令

```powershell
# 啟動（背景）
docker compose up -d

# 啟動並重新 build
docker compose up -d --build

# 查看狀態
docker compose ps

# 查看 log
docker compose logs api --tail 50
docker compose logs deriver --tail 50
docker compose logs -f  # 即時所有 service

# 停止
docker compose stop

# 完整停止並移除 container（資料 volume 保留）
docker compose down

# 停止並移除 volume（⚠️ 資料會消失）
docker compose down -v

# 重啟特定 service
docker compose restart api
docker compose restart deriver

# 在 container 內執行指令
docker compose exec api bash
docker compose exec database psql -U postgres
docker compose exec api uv run alembic current
```

---

## Volume 管理

PostgreSQL 資料存在 named volume `postgres_data`。

```powershell
# 查看 volume 列表
docker volume ls | Select-String "honcho"

# 查看 volume 詳情（存在哪裡）
docker volume inspect honcho_postgres_data

# ⚠️ 刪除 volume（資料永久消失）
docker volume rm honcho_postgres_data
```

---

## 開發模式（hot reload）

在 docker-compose.yml 中取消註解 source mount 段落，可啟用 live reload（程式碼改動自動重啟）。

⚠️ Source mount 在 Windows 上可能有 UID 問題，若有 permission denied 錯誤：
```powershell
# 移除 source mount（直接用 image 內的 code）
# 在 docker-compose.yml 中移除或註解 volumes: - .:/app
```

---

## 監控服務（選填）

官方 compose 內含 Prometheus + Grafana（在開發模式 section）：
- Prometheus：port 9090
- Grafana：port 3000

啟用方式：取消 compose 檔中相關段落的註解，並設定：
```
METRICS_ENABLED=true
```
