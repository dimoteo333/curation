# Curator (큐레이터)

Life Curator: a fully on-device Personal RAG that searches the context of a user’s own life.

> "Like googling, but over my own past records to find answers for today."  
> All core UX (UI text, prompts, model responses) is implemented in Korean.

---

## 1. Overview

Curator is a privacy-first, on-device-first **life curation engine** that indexes a user’s personal records and answers questions from that local context.

The repository currently ships a working mobile app and a FastAPI development harness. The mobile app focuses on local ingestion, local storage, local retrieval, and Korean-first UX.

### Implemented Today

- Korean-first mobile UX for onboarding, asking questions, viewing answers, and settings
- Local encrypted SQLite record storage plus on-device vector retrieval
- Local `.txt` and `.md` file import
- Device calendar import for recent events
- Calendar source-level opt-out for individual calendars
- Import history, recent conversation history, and local data reset
- On-device-first runtime with a remote harness mode for development/testing

### Roadmap

- 🔜 OCR-based image or photo-caption import
- 🔜 STT-based voice memo transcription import
- 🔜 Blog/document import beyond plain text and Markdown
- 🔜 To-do app integrations
- 🔜 Broader Apple Notes / OS-level source integrations where platform support is reliable


## 2. Core Product Concept

### 2.1 Life Curator

Curator treats long‑term personal logs as a single, evolving knowledge base of the user’s life.

Example user question (in Korean):

> **질문:** "나 요즘 왜 이렇게 무기력하지?"

Desired behavior:

- The system searches past records for similar emotions (e.g., 무기력, 번아웃, 우울, 의욕 저하) and related situations (project deadlines, job changes, new side projects, etc.).
- It then generates a Korean answer that connects **current feelings** with **past patterns** and **successful coping strategies**.

Example answer (concept):

> "3년 전 2월에도 비슷한 무기력감을 겪으셨네요. 그때는 ‘새로운 사이드 프로젝트’를 시작하면서 에너지가 많이 회복되었어요. 당시 일기 몇 개를 같이 볼까요?"

### 2.2 Personal RAG (내 인생의 맥락 검색)

Curator does **RAG only over personal data**, not over the public web.

- Step 1: Encode all personal records into vectors and store them in an on-device vector database.
- Step 2: For each user question, encode the query and retrieve top‑k similar records.
- Step 3: Build a Korean prompt that includes the question and the retrieved snippets.
- Step 4: Ask Gemma‑4‑E2B (running locally via LiteRT‑LM) to generate a Korean answer **only** from those snippets.


## 3. Language and Localization

- **Primary UX language:** Korean.
- **LLM instruction language:** Korean system prompt and templates.
- **Input:** Korean user questions (free-form text).
- **Output:** Korean natural language answers, explanations, and references to past records.
- The model is allowed to use English internally, but all visible text to the user (UI labels, explanations, suggestions) must be Korean.


## 4. High‑Level Architecture

### 4.1 Components

- **On-device app runtime**
  - Korean onboarding, ask, answer, timeline, and settings flows
  - On-device-first runtime selection with a remote harness fallback for development
- **Local vector DB**
  - Encrypted SQLite-backed local record storage
  - Local vector retrieval over imported records
- **Implemented connectors**
  - Local `.txt` / `.md` file imports
  - Device calendar imports through the OS calendar store
- **Pre-processing pipeline**
  - Text normalization and metadata extraction
  - Source-aware deduplication for local records
- **Query engine**
  - Query analysis and embedding
  - Vector search and Korean prompt/context assembly

### 4.2 Planned Connectors

- 🔜 Apple Notes deeper integration where platform access is stable
- 🔜 To-do source integration
- 🔜 Blog/document import formats beyond `.txt` / `.md`
- 🔜 OCR-based image import
- 🔜 STT-based voice memo import

### 4.2 Data Flow

1. **Ingestion**
   - Pull new records from authorized sources (with explicit user consent).
   - Assign each record: `id`, `source_type` (diary, calendar, memo, etc.), `created_at`, and metadata.

2. **Pre‑processing & Embedding**
   - Normalize text (handle emojis, line breaks, special characters).
   - Optionally detect language and convert to Korean summaries when needed.
   - Encode each record into a vector and store `(id, vector, metadata)` in the local vector DB.

3. **Query Handling**
   - Receive a Korean user question string.
   - Classify question type (emotion/state, decision, pattern search, meta‑insight, etc.).
   - Embed the question and perform vector search to retrieve top‑k relevant records.

4. **Context Construction**
   - Sort candidates by time, diversity, and source.
   - Compress or summarize if needed to fit into the model context.
   - Build a Korean prompt that lists the snippets with timestamps and sources.

5. **Answer Generation (LLM)**
   - Call Gemma‑4‑E2B via LiteRT‑LM with:
     - Korean system prompt (Life Curator persona + guardrails).
     - User question (in Korean).
     - Retrieved personal record snippets.
   - Generate a Korean answer that:
     - Explains the situation based on past patterns.
     - Shows or offers to show relevant past records.
     - Avoids medical/clinical claims.

6. **Post‑processing**
   - Link record IDs mentioned in the answer to UI navigation.
   - Store user feedback (helpful / not helpful) to improve ranking and prompts.


## 5. On‑Device LLM Stack

### 5.1 LiteRT‑LM

- LiteRT‑LM is Google’s on‑device LLM framework built on top of LiteRT (successor to TensorFlow Lite) for edge devices.
- It provides:
  - Efficient inference on Android, iOS, desktop, and IoT.
  - KV‑cache handling, multi‑stage pipelines, and prompt caching.
  - Integration with Gemma‑4 family models optimized for edge.

### 5.2 Gemma‑4‑E2B

- Gemma‑4 is an open model family from Google DeepMind.
- The **E2B** variant is designed for mobile/edge usage with:
  - Effective parameter size around 2–3B (≈5B including embeddings).
  - Support for long context windows (e.g., up to 128K tokens in Gemma‑4 variants).
  - Multimodal input (text, image, audio) with text output.
- Community and official docs show that Gemma‑4‑E2B can run locally with 4‑bit quantization on devices with ~4–5 GB free RAM.
- A LiteRT‑LM compatible build such as `litert-community/gemma-4-E2B-it-litert-lm` can be used as the primary model.

### 5.3 RAG with Gemma‑4‑E2B

- Use Gemma‑4‑E2B both as:
  - The **generator** (answering in Korean), and
  - Optionally, the **encoder** for text embeddings (using a hidden representation as the vector).
- For better search quality, a separate small embedding model can be added later; but the initial version can reuse Gemma‑4‑E2B to minimize footprint.


## 6. Data Model and Vector DB

### 6.1 Document Schema

Suggested relational schema (SQLite‑style):

```text
Table: documents
  id          TEXT PRIMARY KEY
  source      TEXT        -- "diary", "calendar", "memo", "blog", "photo", "voice_memo" ...
  created_at  INTEGER     -- epoch millis
  title       TEXT
  content     TEXT        -- full text in Korean (or original language)
  meta        TEXT        -- JSON: {"tags": [...], "location": "...", "mood": "...", ...}

Table: embeddings
  doc_id   TEXT    -- FOREIGN KEY → documents.id
  dim      INTEGER
  vector   BLOB    -- float16 or float32 serialized array
```

### 6.2 Search Strategy

- For small/medium personal datasets, brute‑force cosine similarity on vectors may be sufficient.
- For larger datasets (tens/hundreds of thousands of records), use a mobile‑friendly ANN index (e.g., HNSW) on top of the vector table.
- Always keep a time‑aware ranking: recent records may be more relevant for queries like "요즘".


## 7. Korean Prompt Design

### 7.1 System Prompt (Korean, example)

```text
당신은 사용자의 삶의 기록을 함께 돌아보며 통찰을 제공하는 "라이프 큐레이터"입니다.
외부 지식을 사용하지 말고, 주어진 "개인 기록"과 "질문"만을 근거로 답변하세요.

규칙:
- 존댓말을 사용하고, 따뜻하지만 과하게 감정적인 표현은 피합니다.
- 과거에 실제로 존재하는 기록만 인용하고, 없으면 추측하지 말고 "관련 기록을 찾지 못했다"고 말합니다.
- 의학적/심리학적 진단이나 치료 조언을 하지 않습니다. 필요하다면 전문 기관 상담을 권유합니다.
```

### 7.2 RAG Prompt Template (Korean, example)

```text
[질문]
{{user_query_ko}}

[관련 개인 기록들]
{{retrieved_snippets_with_source_and_date_ko}}

위 기록만을 근거로,
- 사용자의 현재 상태를 과거의 패턴과 연결해서 설명하고,
- 과거에 도움이 되었던 행동이나 선택이 있다면 정리해서 제안하세요.
- 참고하면 좋을 기록의 ID도 같이 알려주세요.
```


## 8. Example Logic (Pseudocode)

```python
# 1) Initialize on-device LLM and embedding engine
llm = LiteRTGemma4E2B(
    model_path="/models/gemma-4-e2b-it-litert-lm",
    generation_language="ko",  # always respond in Korean
)
embedder = llm.get_embedding_head()  # or a separate small embedding model

vector_db = LocalVectorDB(db_path="curator.db")

# 2) Index new documents
for doc in fetch_new_documents_from_sources():
    vec = embedder.encode(doc.content)
    vector_db.insert(doc_id=doc.id, vector=vec, metadata=doc.meta)

# 3) Handle a Korean user query
user_query = "나 요즘 왜 이렇게 무기력하지?"
query_vec = embedder.encode(user_query)

candidates = vector_db.search(query_vec, top_k=20)
context = build_korean_context_from_candidates(candidates)

prompt = render_korean_prompt(
    system_prompt=SYSTEM_PROMPT_KO,
    template=PROMPT_TEMPLATE_KO,
    user_query=user_query,
    context=context,
)

answer = llm.generate(prompt, language="ko")
return answer
```


## 9. Privacy and Security Requirements

- All LLM inference (Gemma‑4‑E2B) and vector search must run **fully on device**.
- No raw personal content (diaries, notes, transcripts, captions) is sent to any external server.
- Optional cloud backup or multi-device sync, if ever added, must use end-to-end encryption where only the user holds the keys.
- Access to calendars, photos, microphone, and files must use standard OS permission dialogs.
- Users must be able to exclude specific sources (e.g., work calendar) from ingestion.


## 10. Known Limitations and Non‑Goals

- Curator is **not** a medical or mental‑health product.
  - It must not present itself as a therapist, doctor, or counselor.
- Insights are limited to what has been recorded; unlogged events or feelings cannot be inferred reliably.
- Very long timelines should be summarized or chunked before being passed into the context window.
- On lower‑end devices, quantization and careful scheduling are required to avoid thermal and battery issues.


## 11. Delivery Status

### Shipping

- [x] Local vector DB with encrypted personal text fields
- [x] Local file import for `.txt` and `.md`
- [x] Device calendar import
- [x] Source-level calendar opt-out controls
- [x] Korean-first UX and Korean prompt templates
- [x] Query → embed → search → context assembly pipeline
- [x] Local privacy controls, import history, and delete-local-data flow

### In Progress / Planned

- [ ] 🔜 Broader LiteRT-LM native-runtime maturity across platforms
- [ ] 🔜 Apple Notes / To-do / Calendar integrations where platform support is dependable
- [ ] 🔜 Blog/document import beyond plain text and Markdown
- [ ] 🔜 OCR-based image import
- [ ] 🔜 Voice memo STT import
- [ ] 🔜 On-device feedback and ranking-improvement loop

---

This README is written in English for developers and AI agents, but it defines a service that is implemented and experienced entirely in Korean for end users.
