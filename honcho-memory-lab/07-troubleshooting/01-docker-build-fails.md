# 01 — Docker Build 失敗

---

## 問題：`docker compose up --build` 失敗

### 症狀 A：build 時 Python 依賴安裝失敗

```
Error: Could not find a version that satisfies the requirement ...
```

**原因**：網路問題或 pypi mirror 失效。

**修復**：

```powershell
# 清除 build cache 後重試
docker compose build --no-cache
docker compose up -d
```

---

### 症狀 B：deriver 容器起來又馬上退出（crash loop）

```powershell
docker compose ps
# 看到 deriver: Restarting

docker compose logs deriver --tail=30
```

常見原因與修復：

| 原因 | log 關鍵字 | 修復 |
|------|-----------|------|
| LLM API key 缺失 | `ANTHROPIC_API_KEY` / `authentication` | 在 .env 加入正確 key |
| DB 連線字串錯誤 | `OperationalError` / `psycopg` | 確認 `DATABASE_URI` 格式 |
| Redis 未就緒 | `ConnectionRefusedError: redis` | `docker compose restart redis` |

---

### 症狀 C：DB URI 格式錯誤

```
sqlalchemy.exc.ArgumentError: Could not parse rfc1738 URL
```

**正確格式**：
```
DATABASE_URI=postgresql+psycopg://honcho:honcho@database:5432/honcho
```

❌ 錯誤：`postgresql://...`（缺少 `+psycopg`）

---

### 症狀 D：port 已被佔用

```
Error: Bind for 0.0.0.0:8000 failed: port is already allocated
```

**修復**：

```powershell
# 找佔用的程序
netstat -ano | findstr :8000

# 或修改 .env 改 port
API_PORT=8001
```

---

### 症狀 E：migration 失敗

```
alembic.util.exc.CommandError: Can't locate revision identified by '...'
```

**修復**：

```powershell
# 進入 api 容器
docker compose exec api bash

# 重設 migration 狀態
alembic stamp head
alembic upgrade head
```

---

### 症狀 F：pgvector extension 未安裝

```
ERROR: extension "vector" does not exist
```

**原因**：使用了非 pgvector 版本的 PostgreSQL image。

**修復**：確保 docker-compose.yml 使用：
```yaml
image: pgvector/pgvector:pg16
```
而非 `postgres:16`。

---

## 完整重置（最後手段）

⚠️ 此操作刪除所有本地數據：

```powershell
docker compose down -v    # -v 刪除 volumes（包含 DB 資料）
docker compose up -d --build
```
