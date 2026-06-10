# 01 — 健康檢查

> 三層健康確認：Process / Database / Deriver

---

## 快速健康檢查（一行指令）

```powershell
# 全部一起跑
Invoke-RestMethod -Uri "http://localhost:8000/health"; `
docker compose ps; `
docker compose logs api --tail 5; `
docker compose logs deriver --tail 5
```

---

## Layer 1：Process Health

```powershell
docker compose ps
```

預期所有 service `Status = running`：

```
NAME        IMAGE    SERVICE    STATUS
honcho-api-1        api       running
honcho-deriver-1    deriver   running
honcho-database-1   database  running
honcho-redis-1      redis     running
```

---

## Layer 2：API Process Health

```powershell
Invoke-RestMethod -Uri "http://localhost:8000/health"
```

預期：`{"status":"ok"}`

**注意**：這只確認 process 在跑，不確認 DB。

---

## Layer 3：Database Health（真正的 functional check）

```powershell
Invoke-RestMethod `
    -Uri "http://localhost:8000/v3/workspaces" `
    -Method POST `
    -ContentType "application/json" `
    -Body '{"name": "healthcheck"}'
```

若取回 workspace 物件 → DB 連線正常、migration 完成

---

## Layer 4：Deriver Health

```powershell
docker compose logs deriver --tail 20
```

關鍵字判斷：
- `polling` → Deriver 在等待新工作（正常）
- `processing` → 正在處理 message（正常）
- `error` / `Exception` → 有問題，讀完整 log

---

## Layer 5：Queue Status（進階）

```python
from honcho import Honcho

honcho = Honcho(base_url="http://localhost:8000", workspace_id="healthcheck")
status = honcho.workspaces.get_queue_status(workspace_id="healthcheck")
print(f"Queue pending: {status.pending}")
```

`pending = 0` → 所有 message 已處理完

---

## 自動健康檢查腳本

詳見 `scripts/verify-honcho.ps1`
