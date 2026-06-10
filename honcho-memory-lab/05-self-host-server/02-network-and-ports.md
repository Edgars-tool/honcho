# 02 — Network & Ports

---

## 預設 Port 配置

| Service | Host Port | Container Port | 綁定 |
|---------|-----------|----------------|------|
| API | 8000 | 8000 | `127.0.0.1`（localhost only） |
| PostgreSQL | 5432 | 5432 | `127.0.0.1`（localhost only） |
| Redis | 6379 | 6379 | `127.0.0.1`（localhost only） |
| Deriver | 無 | 無 | 無 HTTP port |
| Prometheus（選填） | 9090 | 9090 | 需手動設定 |
| Grafana（選填） | 3000 | 3000 | 需手動設定 |

---

## Port 衝突處理

若 8000 已被佔用：

```powershell
# 查看哪個程式在用 8000
netstat -ano | Select-String ":8000"
Get-Process -Id (netstat -ano | Select-String ":8000" | ForEach-Object { $_.ToString().Trim().Split()[-1] } | Select-Object -First 1)

# 改 docker-compose.yml 中的 port 映射
# 改為 "127.0.0.1:8001:8000"
```

---

## Docker 容器網路

Honcho 所有 service 在同一個 Docker network 內（`honcho_default` 或類似名稱）。

- Container 之間用 service name 通訊：`api` → `database`、`api` → `redis`
- `localhost` 在 container 內指的是 container 自己，不是 host
- 從 container 連到 host 上的服務（如 Ollama）：用 `host.docker.internal`

```
Container 內的網路名稱對應：
  database → honcho-database-1 container
  redis    → honcho-redis-1 container
  
從 container 連到 host:
  host.docker.internal → Windows/Mac host
```

---

## 對外公開設定（需要時才做）

⚠️ 只在需要從外部存取時才改，默認不要改。

### 方式 1：改 docker-compose.yml（最簡單，但危險）

```yaml
# 改為對所有介面開放（不推薦，直接暴露）
ports:
  - "8000:8000"  # 移除 127.0.0.1
```

**必須同時開啟 Auth**：
```
AUTH_USE_AUTH=true
AUTH_JWT_SECRET=generated-secret
```

### 方式 2：Reverse Proxy（推薦）

在 `127.0.0.1:8000` 前面加 Nginx 或 Caddy，由 reverse proxy 處理 HTTPS。

Nginx 設定範例：
```nginx
server {
    listen 443 ssl;
    server_name honcho.yourdomain.com;
    # ssl 設定略

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Caddy（自動 TLS，最簡單）：
```
honcho.yourdomain.com {
    reverse_proxy localhost:8000
}
```

### 方式 3：Cloudflare Tunnel（不用開 port）

```powershell
# 安裝 cloudflared
winget install Cloudflare.cloudflared

# 登入並建立 tunnel
cloudflared tunnel login
cloudflared tunnel create honcho
cloudflared tunnel route dns honcho honcho.yourdomain.com

# 設定 config（%USERPROFILE%\.cloudflared\config.yml）
# tunnel: <your-tunnel-id>
# credentials-file: C:\Users\YourName\.cloudflared\<tunnel-id>.json
# ingress:
#   - hostname: honcho.yourdomain.com
#     service: http://localhost:8000
#   - service: http_status:404

# 啟動
cloudflared tunnel run honcho
```
