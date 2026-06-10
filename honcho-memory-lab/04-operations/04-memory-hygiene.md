# 04 — 記憶品質維護（Memory Hygiene）

---

## 什麼是記憶污染

- **錯誤結論**：Deriver 從誤導性對話萃取了不正確的事實
- **過時記憶**：使用者偏好已改變，但舊結論未更新
- **重複記憶**：同一件事被存了多次（Dreamer 會自動整合，但不是立即）
- **無意義結論**：測試訊息被萃取為真實結論

---

## 查詢現有 Conclusions

```python
# list_conclusions.py
from honcho import Honcho

honcho = Honcho(base_url="http://localhost:8000", workspace_id="your-workspace")

# 列出某個 peer 的所有 conclusions
conclusions = honcho.conclusions.list(
    workspace_id="your-workspace",
    peer_id="target-peer-id",
    limit=50
)

for c in conclusions:
    print(f"ID: {c.id}")
    print(f"Content: {c.content[:200]}")
    print(f"Created: {c.created_at}")
    print("---")
```

---

## 語義搜尋 Conclusions

```python
# search_conclusions.py
from honcho import Honcho

honcho = Honcho(base_url="http://localhost:8000", workspace_id="your-workspace")

results = honcho.conclusions.query(
    workspace_id="your-workspace",
    peer_id="target-peer-id",
    query="關鍵字搜尋",
    top_k=10
)

for r in results:
    print(f"Score: {r.score:.3f} | {r.content[:150]}")
```

---

## 刪除錯誤結論

```python
# delete_conclusion.py
from honcho import Honcho

honcho = Honcho(base_url="http://localhost:8000", workspace_id="your-workspace")

# 刪除特定 conclusion
honcho.conclusions.delete(
    workspace_id="your-workspace",
    conclusion_id="conclusion-id-to-delete"
)
print("結論已刪除")
```

---

## 清除測試資料

```python
# cleanup_test_workspace.py
from honcho import Honcho

# 刪除整個測試 workspace（連帶刪除所有 peers / sessions / messages / conclusions）
honcho = Honcho(base_url="http://localhost:8000", workspace_id="test-workspace")
honcho.workspaces.delete(workspace_id="test-workspace")
print("測試 workspace 已刪除（背景處理）")
```

⚠️ Workspace 刪除是非同步的，在背景執行，不是立即完成。

---

## 記憶品質評估

```python
# memory_quality.py
from honcho import Honcho

honcho = Honcho(base_url="http://localhost:8000", workspace_id="your-workspace")

# 評估：Dialectic 回答是否合理
response = honcho.peers.chat(
    workspace_id="your-workspace",
    peer_id="target-peer",
    query="Summarize everything you know about this user. Be specific with facts."
)

print("=== 記憶品質評估 ===")
print(response)
print("\n請人工評估：")
print("1. 事實是否正確？")
print("2. 是否有過時資訊？")
print("3. 是否有重複或矛盾？")
```

---

## 記憶修正流程

1. **發現問題**：使用者反映記憶錯誤，或你注意到 Dialectic 回答不對
2. **語義搜尋定位**：用關鍵字找到相關 conclusions
3. **人工審查**：確認哪些是錯誤的
4. **刪除錯誤結論**：呼叫 delete API
5. **（選填）手動建立正確結論**：用 `create_conclusions` 補正
6. **觸發 Dreamer 重新整合**：`POST /workspaces/{id}/dream`
7. **重新驗證**：再次查詢 Dialectic 確認改善

---

## 預防記憶污染

- 測試用獨立 workspace（如 `test-xxx`），完成後刪除
- 不要把 debug 訊息、錯誤訊息當作 user message 寫入
- 明確區分「使用者說的話」和「系統 log」
- 定期審查 Dialectic 回答品質
