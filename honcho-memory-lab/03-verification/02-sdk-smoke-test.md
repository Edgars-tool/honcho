# 02 — SDK Smoke Test（基本功能驗證）

> **每一段指令都是完整的複製貼上區塊。** 不需要手動修改任何檔案。

---

## 前置：確認環境變數已設定

```powershell
echo $env:HONCHO_API_KEY
```

**看到你的 Key** → 繼續。

**空白** → 先設定：

```powershell
$env:HONCHO_API_KEY = "hch-你的Key貼這裡"
```

---

## Python SDK Smoke Test

### 1. 建立測試腳本

進入你的測試資料夾後，複製整個區塊貼上（含 `@'` 開頭和結尾）：

```powershell
Set-Location "$HOME\honcho-test"
```

```powershell
@'
import os
from honcho import Honcho

API_KEY = os.environ.get("HONCHO_API_KEY", "")
if not API_KEY:
    raise SystemExit("ERROR: 請先設定 HONCHO_API_KEY 環境變數")

honcho = Honcho(api_key=API_KEY)
WORKSPACE = "smoke-test-workspace"
PEER      = "smoke-test-peer"
SESSION   = "smoke-test-session"

print("=== Python SDK Smoke Test ===")

# Test 1: Workspace
ws = honcho.workspaces.get_or_create(name=WORKSPACE)
print(f"[1/4] Workspace OK: {ws.name}")

# Test 2: Peer
peer = honcho.peers.get_or_create(workspace_name=WORKSPACE, name=PEER)
print(f"[2/4] Peer OK: {peer.name}")

# Test 3: Session + Message
session = honcho.sessions.get_or_create(
    workspace_name=WORKSPACE, peer_name=PEER, session_name=SESSION
)
honcho.messages.create_batch(
    workspace_name=WORKSPACE,
    peer_name=PEER,
    session_name=SESSION,
    messages=[
        {"role": "user",      "content": "Smoke test message: hello"},
        {"role": "assistant", "content": "Smoke test reply: world"},
    ]
)
print("[3/4] Messages OK")

# Test 4: List messages
msgs = list(honcho.messages.list(
    workspace_name=WORKSPACE, peer_name=PEER, session_name=SESSION
))
assert len(msgs) >= 2, "Expected at least 2 messages"
print(f"[4/4] List Messages OK: {len(msgs)} messages found")

print()
print("=== 全部通過！SDK 運作正常 ===")
'@ | Out-File -FilePath "smoke-test.py" -Encoding utf8
```

### 2. 執行測試

```powershell
python smoke-test.py
```

**預期輸出**：

```
=== Python SDK Smoke Test ===
[1/4] Workspace OK: smoke-test-workspace
[2/4] Peer OK: smoke-test-peer
[3/4] Messages OK
[4/4] List Messages OK: 2 messages found

=== 全部通過！SDK 運作正常 ===
```

---

## TypeScript SDK Smoke Test

> TypeScript SDK 測試需要 Node.js 和 npm。如果沒裝 Node.js，跳過此部分。

### 確認 Node.js

```powershell
node --version
npm --version
```

**兩個都看到版本號** → 繼續。**看到錯誤** → 跳過此部分。

### 1. 初始化並安裝

```powershell
New-Item -ItemType Directory -Path "$HOME\honcho-ts-test" -Force
Set-Location "$HOME\honcho-ts-test"
```

```powershell
npm init -y
npm install honcho-ai
```

### 2. 建立測試腳本

```powershell
@'
const Honcho = require("honcho-ai").default;

const API_KEY = process.env.HONCHO_API_KEY || "";
if (!API_KEY) {
  console.error("ERROR: 請先設定 HONCHO_API_KEY 環境變數");
  process.exit(1);
}

(async () => {
  const honcho = new Honcho({ apiKey: API_KEY });
  const WORKSPACE = "ts-smoke-test";
  const PEER      = "ts-peer";

  console.log("=== TypeScript SDK Smoke Test ===");

  const ws   = await honcho.workspaces.getOrCreate({ name: WORKSPACE });
  console.log(`[1/2] Workspace OK: ${ws.name}`);

  const peer = await honcho.peers.getOrCreate({
    workspaceName: WORKSPACE, name: PEER
  });
  console.log(`[2/2] Peer OK: ${peer.name}`);

  console.log();
  console.log("=== 全部通過！TypeScript SDK 運作正常 ===");
})();
'@ | Out-File -FilePath "smoke-test.js" -Encoding utf8
```

### 3. 執行測試

```powershell
node smoke-test.js
```

**預期輸出**：

```
=== TypeScript SDK Smoke Test ===
[1/2] Workspace OK: ts-smoke-test
[2/2] Peer OK: ts-peer

=== 全部通過！TypeScript SDK 運作正常 ===
```

---

## 出錯時

| 錯誤 | 解法 |
|------|------|
| `HONCHO_API_KEY 未設定` | 重新執行 `$env:HONCHO_API_KEY = "hch-..."` |
| `AuthenticationError` | Key 錯誤，重新檢查 |
| `ModuleNotFoundError` | 重新執行 `pip install honcho-ai` |
| assertion 失敗 | 訊息數量不對，重跑一次（偶爾網路延遲）|

---

## 通過後

→ `03-context-retrieval-test.md` — 測試完整記憶流（寫入→等待→查詢）
