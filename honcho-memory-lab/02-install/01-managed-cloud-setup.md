# 01 — Managed Cloud 設定（雲端版，最快）

> **零基礎可用。** 每一步都有完整的複製貼上指令。
>
> 如果你從沒用過終端機，先看 `../00-beginner-start.md`。

---

## 需要準備什麼

- 一個瀏覽器
- Python 3.10 以上（不確定？看步驟 1）
- 網路

---

## 步驟 1：確認 Python

開啟 PowerShell（按 `Win + R`，輸入 `powershell`，Enter），複製貼上：

```powershell
python --version
```

**看到** `Python 3.10.x` 或更新 → 繼續。

**看到「找不到命令」** → 去 https://www.python.org/downloads/ 下載，安裝時勾選「Add Python to PATH」，裝好後重新開 PowerShell。

---

## 步驟 2：安裝 Honcho SDK

```powershell
pip install honcho-ai
```

等出現 `Successfully installed honcho-ai-...` 再繼續。

---

## 步驟 3：取得 API Key

1. 開瀏覽器，前往 **https://app.honcho.dev**
2. 登入（可用 Google 帳號）
3. 左側點 **API Keys** → **Create Key**
4. 複製 Key（格式：`hch-xxxxxxxx...`），先貼在記事本

---

## 步驟 4：設定環境變數

把 `hch-你的Key貼這裡` 換成你的真實 Key，複製整行貼上：

```powershell
$env:HONCHO_API_KEY = "hch-你的Key貼這裡"
```

確認設定成功：

```powershell
echo $env:HONCHO_API_KEY
```

**看到你的 Key 顯示出來** → 正確。

---

## 步驟 5：建立並執行連線測試

### 5a. 建立測試資料夾

```powershell
New-Item -ItemType Directory -Path "$HOME\honcho-test" -Force
Set-Location "$HOME\honcho-test"
```

### 5b. 建立測試腳本

完整複製下面區塊（從 `@'` 到最後一行），貼上，按 Enter：

```powershell
@'
import os
from honcho import Honcho

api_key = os.environ.get("HONCHO_API_KEY", "")
if not api_key:
    print("ERROR: HONCHO_API_KEY 未設定，請先執行步驟 4")
    exit(1)

honcho = Honcho(api_key=api_key)

workspace = honcho.workspaces.get_or_create(name="my-first-workspace")
peer = honcho.peers.get_or_create(
    workspace_name="my-first-workspace",
    name="alice"
)
session = honcho.sessions.get_or_create(
    workspace_name="my-first-workspace",
    peer_name="alice",
    session_name="session-001"
)

print("OK 連線成功！")
print(f"  Workspace: {workspace.name}")
print(f"  Peer: {peer.name}")
print(f"  Session: {session.name}")
'@ | Out-File -FilePath "test-connection.py" -Encoding utf8
```

### 5c. 執行測試

```powershell
python test-connection.py
```

**預期輸出**：

```
OK 連線成功！
  Workspace: my-first-workspace
  Peer: alice
  Session: session-001
```

---

## 步驟 6：記憶寫入與查詢測試

### 6a. 建立記憶測試腳本

```powershell
@'
import os, time
from honcho import Honcho

api_key = os.environ.get("HONCHO_API_KEY", "")
honcho = Honcho(api_key=api_key)

honcho.messages.create_batch(
    workspace_name="my-first-workspace",
    peer_name="alice",
    session_name="session-memory-001",
    messages=[
        {"role": "user",      "content": "我是設計師，平常用 Figma 工作。"},
        {"role": "assistant", "content": "了解，你是用 Figma 的設計師。"},
        {"role": "user",      "content": "我討厭開太多 Zoom 會議。"},
        {"role": "assistant", "content": "記住了，你不喜歡太多會議。"},
    ]
)
print("OK 對話寫入完成，等待記憶處理（20 秒）...")
time.sleep(20)

response = honcho.peers.chat(
    workspace_name="my-first-workspace",
    peer_name="alice",
    queries=["Alice 的工作背景是什麼？"]
)
print("OK Honcho 記憶回覆：")
print(response.content)
'@ | Out-File -FilePath "test-memory.py" -Encoding utf8
```

### 6b. 執行記憶測試

```powershell
python test-memory.py
```

**預期**：回覆包含「設計師」、「Figma」等關鍵字，代表記憶系統正常。

---

## 出錯時

| 錯誤訊息 | 解法 |
|----------|------|
| `HONCHO_API_KEY 未設定` | 重新執行步驟 4 |
| `AuthenticationError` | Key 貼錯，確認沒有多餘空格 |
| `ModuleNotFoundError: honcho` | 重新執行 `pip install honcho-ai` |
| `ConnectionError` | 確認網路，或稍後再試 |
| PowerShell 貼上沒反應 | 在黑色視窗「按右鍵」貼上 |

---

## 完成後

- 驗證所有功能 → `../03-verification/00-verification-checklist.md`
- 想自架（不用付費 API）→ `02-self-host-docker-setup.md`
- Key 永久設定：搜尋系統「編輯系統環境變數」，新增 `HONCHO_API_KEY`
