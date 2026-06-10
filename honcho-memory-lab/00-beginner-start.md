# 零基礎新手起始指南

> **你不需要懂程式。** 只要照順序把灰色方塊裡的文字複製貼上到終端機，按 Enter 就好。

---

## 第一步：開啟 PowerShell（終端機）

**方法一（最快）**：按鍵盤 `Win + R`，輸入 `powershell`，按 Enter。
溫**方法二**：按鍵盤 `Win`，搜尋「PowerShell」，點擊「Windows PowerShell」。

> 你會看到一個黑色或藍色視窗，左邊有 `PS C:\...>` 這樣的文字，這就對了。

---

## 第二步：確認 Python 有沒有裝

把下面這行完整複製，貼進 PowerShell，按 Enter：

```powershell
python --version
```

**預期看到**：`Python 3.10.x`（或更新版本）

**如果看到「找不到命令」**：去 https://www.python.org/downloads/ 下載安裝 Python，安裝時勾選「Add Python to PATH」。安裝後關掉 PowerShell 重新開。

---

## 第三步：安裝 Honcho Python 套件

複製貼上，按 Enter，等待安裝完成（約 30 秒）：

```powershell
pip install honcho-ai
```

**預期看到**：最後一行出現 `Successfully installed honcho-ai-...`

---

## 第四步：取得 Honcho API Key

1. 打開瀏覽器，前往 https://app.honcho.dev
2. 登入（可用 Google 帳號）
3. 點擊左側 **API Keys**
4. 點擊 **Create Key**，複製出現的 key（格式：`hch-xxxxxxxx...`）

> ⚠️ Key 只顯示一次，請先貼到記事本存起來。

---

## 第五步：建立並執行測試檔案

### 5a. 建立測試資料夾

複製貼上，按 Enter：

```powershell
New-Item -ItemType Directory -Path "$HOME\honcho-test" -Force
Set-Location "$HOME\honcho-test"
```

**預期看到**：顯示資料夾路徑，沒有錯誤訊息。

---

### 5b. 建立測試檔案

複製下面**整個區塊**（從 `@'` 到最後一行），貼上，按 Enter：

> ⚠️ 把 `hch-在這裡貼上你的Key` 換成你在第四步拿到的實際 Key，再複製整個區塊。

```powershell
@'
from honcho import Honcho

# ← 把下面這行的 Key 換成你的真實 Key
HONCHO_API_KEY = "hch-在這裡貼上你的Key"

honcho = Honcho(api_key=HONCHO_API_KEY)

# 建立 workspace 和 peer
workspace = honcho.workspaces.get_or_create(name="my-first-workspace")
peer = honcho.peers.get_or_create(
    workspace_name="my-first-workspace",
    name="alice"
)

# 建立對話 session
session = honcho.sessions.get_or_create(
    workspace_name="my-first-workspace",
    peer_name="alice",
    session_name="session-001"
)

print("✓ 連線成功！")
print(f"  Workspace: {workspace.name}")
print(f"  Peer: {peer.name}")
print(f"  Session: {session.name}")
'@ | Out-File -FilePath "test-honcho.py" -Encoding utf8
```

---

### 5c. 執行測試

```powershell
python test-honcho.py
```

**預期看到**：

```
✓ 連線成功！
  Workspace: my-first-workspace
  Peer: alice
  Session: session-001
```

**如果看到錯誤** → 看下方「常見問題」。

---

## 第六步：寫入一條記憶並查詢

建立第二個測試檔案（一樣整段複製貼上，把 Key 換掉）：

```powershell
@'
import time
from honcho import Honcho

HONCHO_API_KEY = "hch-在這裡貼上你的Key"

honcho = Honcho(api_key=HONCHO_API_KEY)

# 寫入對話
session = honcho.sessions.get_or_create(
    workspace_name="my-first-workspace",
    peer_name="alice",
    session_name="session-memory-test"
)

honcho.messages.create_batch(
    workspace_name="my-first-workspace",
    peer_name="alice",
    session_name="session-memory-test",
    messages=[
        {"role": "user", "content": "我喜歡喝咖啡，每天早上一杯。"},
        {"role": "assistant", "content": "了解，你每天早上都喝咖啡。"},
    ]
)
print("✓ 訊息寫入完成，等待 Honcho 記憶處理（約 15 秒）...")
time.sleep(15)

# 查詢記憶
response = honcho.peers.chat(
    workspace_name="my-first-workspace",
    peer_name="alice",
    queries=["Alice 有什麼飲食習慣？"]
)
print("✓ Honcho 記憶回覆：")
print(response.content)
'@ | Out-File -FilePath "test-memory.py" -Encoding utf8
```

執行：

```powershell
python test-memory.py
```

**預期看到**：Honcho 的回覆包含「咖啡」相關內容，代表記憶系統正常運作。

---

## 常見問題

| 錯誤訊息 | 解法 |
|----------|------|
| `ModuleNotFoundError: No module named 'honcho'` | 重新執行 `pip install honcho-ai` |
| `AuthenticationError` | API Key 輸入錯誤，確認沒有多餘空格 |
| `ConnectionError` | 確認網路正常，或稍後再試 |
| PowerShell 貼上後沒反應 | 在 PowerShell 視窗按右鍵貼上（Ctrl+V 有時無效） |

---

## 下一步

- 想了解 Honcho 是什麼 → `01-learning/00-Honcho-系統地圖.md`
- 想自架伺服器（不用付費 API）→ `02-install/02-self-host-docker-setup.md`
- 出問題 → `07-troubleshooting/00-common-issues.md`
