# 04 — 環境變數模板

> 所有重要的 env var 說明，配合 .env.template 使用

⚠️ 這份文件只列變數名稱和說明，**不含真實值**。真實值只存在本機 `.env`，不進 repo。

---

## 最小必要設定（Docker 自架）

```dotenv
# .env — 最小設定，可啟動

# LLM（必填，至少一個）
LLM_OPENAI_API_KEY=sk-placeholder

# 認證（開發環境先關閉）
AUTH_USE_AUTH=false

# Log
LOG_LEVEL=INFO
```

資料庫連線在 docker-compose.yml 的 `environment` section 設定，不需要在 `.env` 重複。

---

## 完整 LLM 設定說明

```dotenv
# OpenAI（預設 provider，embeddings 必用）
LLM_OPENAI_API_KEY=sk-placeholder

# Anthropic（Dialectic high/max 層預設用）
LLM_ANTHROPIC_API_KEY=sk-ant-placeholder

# Google Gemini（Deriver / Dialectic minimal/low 預設用）
LLM_GEMINI_API_KEY=AI-placeholder

# 覆蓋 Deriver 使用的 model（可選，用於切換 provider）
DERIVER_MODEL_CONFIG__TRANSPORT=openai
DERIVER_MODEL_CONFIG__MODEL=gpt-4o-mini
# DERIVER_MODEL_CONFIG__OVERRIDES__BASE_URL=https://openrouter.ai/api/v1

# 覆蓋 Dialectic model
# DIALECTIC_LEVELS__minimal__MODEL_CONFIG__MODEL=gemini-2.0-flash
```

---

## 資料庫設定（手動安裝時）

```dotenv
# 注意：必須用 postgresql+psycopg，不是 postgresql://
DB_CONNECTION_URI=postgresql+psycopg://postgres:PLACEHOLDER@localhost:5432/postgres

# Connection pool
DB_POOL_SIZE=10
DB_MAX_OVERFLOW=20
```

---

## Redis 設定（選填）

```dotenv
# 啟用 Redis cache
CACHE_ENABLED=true
CACHE_URL=redis://localhost:6379/0

# 停用（預設，使用 in-memory fallback）
CACHE_ENABLED=false
```

---

## 認證設定

```dotenv
# 開發環境
AUTH_USE_AUTH=false

# Production（必開）
AUTH_USE_AUTH=true
AUTH_JWT_SECRET=GENERATE_WITH_python_scripts/generate_jwt_secret.py
```

生成 JWT secret：
```powershell
# 在 honcho repo 目錄內
uv run python scripts/generate_jwt_secret.py
```

---

## Deriver 效能設定

```dotenv
# 同時運行幾個 Deriver worker
DERIVER_WORKERS=1  # 增加到 4 可提升吞吐量

# Token 批次設定（太高可能導致 Deriver 看起來沒在動）
REPRESENTATION_BATCH_MAX_TOKENS=25000
```

---

## Summarizer 設定

```dotenv
SUMMARY_MESSAGES_PER_SHORT_SUMMARY=20
SUMMARY_MESSAGES_PER_LONG_SUMMARY=60
```

---

## Monitoring（選填）

```dotenv
# Prometheus metrics
METRICS_ENABLED=true

# Sentry 錯誤追蹤
SENTRY_ENABLED=true
SENTRY_DSN=https://placeholder@sentry.io/project-id
```

---

## 使用 Ollama（本機 LLM）

```dotenv
LLM_OPENAI_API_KEY=ollama  # 隨便一個非空值

DERIVER_MODEL_CONFIG__TRANSPORT=openai
DERIVER_MODEL_CONFIG__MODEL=llama3.2
# Docker 內用 host.docker.internal，手動安裝用 localhost
DERIVER_MODEL_CONFIG__OVERRIDES__BASE_URL=http://host.docker.internal:11434/v1
DERIVER_MODEL_CONFIG__THINKING_BUDGET_TOKENS=0  # Ollama 不支援 thinking
```

---

## .gitignore 必填

```
.env
*.env
!.env.template
```
