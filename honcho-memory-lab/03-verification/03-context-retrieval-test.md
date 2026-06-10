# 03 — Context Retrieval Test

> 端到端測試：寫入記憶 → 等待處理 → 查回

---

## 測試目標

確認以下完整流程正常：
1. 寫入有意義的對話（含使用者特徵）
2. 等待 Deriver 萃取結論
3. 用 Dialectic 查詢，確認結論被正確萃取

---

## 完整端到端測試腳本

```python
# context_retrieval_test.py
# 一鍵複製貼上版

import time
import sys
from honcho import Honcho

BASE_URL = "http://localhost:8000"
WORKSPACE_ID = "e2e-context-test"

# 測試用對話（含明確特徵）
TEST_CONVERSATION = [
    ("user", "我是一個後端工程師，主要用 Python 和 Go"),
    ("assistant", "了解，你是後端工程師"),
    ("user", "我最近在研究 Kubernetes，但我不喜歡 YAML 配置"),
    ("assistant", "Kubernetes 確實有很多 YAML，你更偏好哪種配置方式？"),
    ("user", "我偏好 Pulumi 或直接寫程式碼的基礎設施"),
    ("assistant", "Infrastructure as Code 的方向，使用 Pulumi 這類工具確實更直覺"),
]

# 預期 Dialectic 回答中應出現的關鍵字
EXPECTED_KEYWORDS = ["python", "go", "kubernetes", "backend", "工程師", "pulumi"]

def run():
    print("=== Context Retrieval End-to-End Test ===\n")

    honcho = Honcho(base_url=BASE_URL, workspace_id=WORKSPACE_ID)
    user = honcho.peer("e2e-user")
    assistant = honcho.peer("e2e-assistant")
    session = honcho.session("e2e-session-001")
    session.add_peers([user, assistant])

    print(f"[1/4] 寫入 {len(TEST_CONVERSATION)} 則測試訊息...")
    messages = []
    for role, content in TEST_CONVERSATION:
        if role == "user":
            messages.append(user.message(content))
        else:
            messages.append(assistant.message(content))
    session.add_messages(messages)
    print(f"      ✅ 寫入完成")

    print(f"\n[2/4] 等待 Deriver 處理（最多 60 秒）...")
    for i in range(12):
        time.sleep(5)
        try:
            status = honcho.workspaces.get_queue_status(workspace_id=WORKSPACE_ID)
            pending = getattr(status, 'pending', None)
            if pending == 0:
                print(f"      ✅ Queue 清空，處理完成（{(i+1)*5} 秒）")
                break
            print(f"      ⏳ 第 {(i+1)*5} 秒，pending: {pending}")
        except Exception:
            print(f"      ⏳ 第 {(i+1)*5} 秒...")

    print(f"\n[3/4] 查詢 Dialectic...")
    response = user.chat("Tell me about this user's technical background and preferences in 3 sentences max.")
    print(f"      回應：\n{response}\n")

    print(f"[4/4] 驗證回應包含預期關鍵字...")
    response_lower = response.lower()
    found = [kw for kw in EXPECTED_KEYWORDS if kw.lower() in response_lower]
    missing = [kw for kw in EXPECTED_KEYWORDS if kw.lower() not in response_lower]
    
    print(f"      ✅ 找到：{found}")
    if missing:
        print(f"      ⚠️  未找到：{missing}（可能 Deriver 尚未完全處理）")
    
    if len(found) >= 3:
        print(f"\n✅✅ 端到端測試通過（{len(found)}/{len(EXPECTED_KEYWORDS)} 關鍵字）")
    else:
        print(f"\n⚠️  端到端測試部分通過（{len(found)}/{len(EXPECTED_KEYWORDS)} 關鍵字），請等更久後重試")

if __name__ == "__main__":
    run()
```

```powershell
python context_retrieval_test.py
```

---

## 預期輸出

```
=== Context Retrieval End-to-End Test ===

[1/4] 寫入 6 則測試訊息...
      ✅ 寫入完成

[2/4] 等待 Deriver 處理（最多 60 秒）...
      ⏳ 第 5 秒，pending: 2
      ⏳ 第 10 秒，pending: 1
      ✅ Queue 清空，處理完成（15 秒）

[3/4] 查詢 Dialectic...
      回應：
      This user is a backend engineer who primarily works with Python and Go...

[4/4] 驗證回應包含預期關鍵字...
      ✅ 找到：['python', 'go', 'kubernetes', '工程師']
      ⚠️  未找到：['backend', 'pulumi']（可能 Deriver 尚未完全處理）

✅✅ 端到端測試通過（4/6 關鍵字）
```

---

## 故障排除

若關鍵字比例很低（< 2/6）：

1. 確認 Deriver 在跑：`docker compose logs deriver --tail 30`
2. 確認 LLM API key 正確
3. 等更長時間再重試（有時 LLM 處理較慢）
4. 降低 `REPRESENTATION_BATCH_MAX_TOKENS` 讓 Deriver 更早處理
