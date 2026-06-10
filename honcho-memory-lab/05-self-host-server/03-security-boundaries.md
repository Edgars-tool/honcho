# 03 — 安全邊界

---

## 預設安全設定（開箱即用）

| 設定 | 預設值 | 說明 |
|------|--------|------|
| `AUTH_USE_AUTH` | `false` | 無認證（開發用）|
| Port 綁定 | `127.0.0.1` | 只接受本機連線 |
| HTTPS | 無 | 由 reverse proxy 處理 |
| DB port | `127.0.0.1:5432` | 只接受本機連線 |
| Redis port | `127.0.0.1:6379` | 只接受本機連線 |

**本機開發不需要改任何東西**。

---

## 對外公開前的安全 Checklist

```
[ ] AUTH_USE_AUTH=true
[ ] AUTH_JWT_SECRET 已生成並設定
[ ] HTTPS 通道設定完成（reverse proxy 或 Cloudflare Tunnel）
[ ] DB port 仍然綁定 127.0.0.1（不對外暴露）
[ ] Redis port 仍然綁定 127.0.0.1（不對外暴露）
[ ] .env 不在 repo 中
[ ] 備份策略就緒
[ ] Firewall 只開放 443（HTTPS）
```

---

## JWT Secret 生成

```powershell
# 在 honcho repo 目錄內
uv run python scripts/generate_jwt_secret.py
# 複製輸出，設定到 .env
# AUTH_JWT_SECRET=<generated_value>
```

---

## API Key（Scoped JWT）

開啟 Auth 後，可以生成 scoped JWT：

```python
# 生成限定 workspace 的 API key
from honcho import Honcho

# 需要先用 admin JWT 初始化
honcho = Honcho(
    base_url="http://localhost:8000",
    workspace_id="my-workspace",
    api_key="admin-jwt-token"
)

# 建立 scoped key（只能存取特定 workspace）
key = honcho.keys.create(
    workspace_id="my-workspace",
    # 可設定 scope: workspace / peer / session
)
print(f"Scoped key: {key.key}")
```

---

## 資料隔離保證

- Workspace 之間：schema 層 composite FK 強制隔離，結構上不可能跨 workspace 洩漏
- Peer 之間：Collection 以 `(observer, observed)` pair 為 key，隔離清晰
- DB / Redis：只對 localhost 開放，不對網路暴露

---

## 常見安全錯誤

| 錯誤 | 後果 | 避免方式 |
|------|------|----------|
| 將 `.env` commit 進 git | API key / DB 密碼洩露 | `.gitignore` 必填 |
| DB port 對外開放 | 任何人都能存取資料庫 | 確認 port 綁定 `127.0.0.1` |
| 沒開 Auth 就對外公開 | 任何人都能讀寫 Honcho | 對外前必開 Auth |
| 在 production 用 `AUTH_USE_AUTH=false` | 無認證漏洞 | 開 Auth，用 scoped JWT |
| Secrets 寫在程式碼裡 | Repo 洩露 | 用環境變數或 secrets manager |
