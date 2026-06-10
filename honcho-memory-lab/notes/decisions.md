# 決策紀錄

> 記錄對此 lab 的架構與設定決策，供未來參考

---

## 格式

```
## [YYYY-MM-DD] 決策標題
**情境**：...
**選擇**：...
**理由**：...
**取捨**：...
```

---

## [2026-06-07] 選擇 Managed Cloud 作為首要測試環境

**情境**：需要快速驗證 Honcho 功能，同時評估 self-hosted 可行性。

**選擇**：先用 Managed Cloud（app.honcho.dev），同時準備 Docker 自架環境。

**理由**：
- Managed Cloud 零設定，可立即測試 API 行為
- Docker 自架需要時間設定 pgvector、Redis 等

**取捨**：
- Managed Cloud 資料在外部，需確認隱私需求
- Self-hosted 完全掌控，但維護成本高

---

## [待填寫] 未來決策

| 決策問題 | 選項 A | 選項 B | 決定 |
|----------|--------|--------|------|
| 對外公開方式 | Cloudflare Tunnel | Nginx Reverse Proxy | 待評估 |
| LLM provider | Anthropic | OpenRouter | 待評估 |
| 備份策略 | 本機 pg_dump | 雲端備份 | 待評估 |
| Auth 開啟時機 | 開發完再開 | 一開始就開 | 待評估 |
