# 學習筆記

> 理解 Honcho 過程中的洞察與心得

---

## 架構理解

### Peer Paradigm 的設計意圖

Honcho 把「人」和「AI agent」統一成 Peer，讓系統天然支援多種角色：

- Human ↔ AI 的對話
- AI ↔ AI 的多 agent 協作
- 同一個人在不同 context 下的不同 peer

Key insight：`(observer, observed)` 這個 pair 是記憶的 key。
- Alice 自我觀察 → `(alice, alice)` → 自我 representation
- AI 觀察 Alice → `(assistant, alice)` → AI 對 Alice 的理解

---

### Minimal Deriver 設計

Deriver 不是 agent（不用 tool loop），是「單一結構化 LLM call」。

好處：可預測成本、低延遲。
代價：靈活度低，無法在 extraction 過程中主動查詢更多上下文。

Dreamer 才是 agentic，用 DeductionSpecialist + InductionSpecialist 深度推理。

---

### API 設計特點

大部分 list/search endpoint 用 `POST` 而非 `GET`，因為需要傳遞 filter body。
這與一般 REST 慣例不同，初次使用要注意。

---

### 兩個獨立程序的必要性

API server 和 Deriver worker 分離是刻意設計：
- API 絕對不能 block 在 LLM call 上（HTTP timeout 問題）
- Deriver 可以獨立 scale（多 instance）
- 兩者只透過 PostgreSQL queue 和 Redis 溝通

---

## 實用洞察

### 測試時的 Workspace 策略

建議開發/測試用獨立 workspace，避免污染正式資料：

```python
# 開發
honcho = Honcho(base_url="...", api_key="...")
workspace = honcho.workspaces.get_or_create(name="dev-testing")

# 正式
workspace = honcho.workspaces.get_or_create(name="production")
```

### Dialectic 費用意識

每次 `peer.chat()` 都是一次（或多次）LLM call。
`minimal` tier 最便宜，`max` tier 最貴但最聰明。
語義搜尋 `conclusions.query()` 不需要 LLM，便宜得多。

---

## 待深入研究

- [ ] Dreamer 的 surprisal-based prioritization 實際效果
- [ ] Reasoning tree 如何影響 Dialectic 回應品質
- [ ] Multi-peer session 的實際應用場景
- [ ] Custom deriver instructions 的撰寫技巧
- [ ] Webhook 整合的實際使用方式
