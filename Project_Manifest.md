# Project Manifest: Ugandan Constitution Hub

## 1. Project Overview
A high-performance, local-first, AI-heavy mobile application designed to democratize access to the Ugandan Constitution 1995. It guarantees 100% offline access to the text for users in remote areas while offering intelligent search capabilities.

## 2. Technical Stack
- **Frontend:** Flutter
- **Local DB:** Isar (for NoSQL, high-speed offline access)
- **Backend/Cloud Sync:** Supabase (PostgreSQL + pgvector for RAG embeddings and syncing updates)
- **AI Engine:** Gemini 3.1 Pro (via `google_generative_ai` Dart SDK)

## 3. Data Architecture
- **Source:** 1995 Ugandan Constitution
- **Processing:** Converted from PDF into a structured, machine-readable JSON schema (`constitution.json`).
- **Data Model:** Contains `officialText`, `simpleSummary`, `keywords`, structured by `Chapter` and `Article`.

## 4. Persona Modules
- **Citizen Mode:** Actionable insights, "Emergency Rights" capabilities, and "Simple English" summaries for accessibility.
- **Pro View (Lawyer Mode):** Advanced comparisons, split-screen layouts, exact citations, and high-legibility legal typography.
- **Student Mode:** "Search-First" capabilities with semantic search (RAG) to translate intent into correct constitutional references.

## 5. UI/UX Design
- **Theme:** High-contrast accessibility reflecting Ugandan flag colors (Black, Yellow, Red).
- **Architecture:** "Search-First" layout prioritizing direct access and natural language inquiries.

## 6. Implementation Phases
1. **System Analysis & Data Ingestion** - Parsing the Constitution into structured JSON.
2. **UI/UX Design** - Building Citizen, Pro, and Search modes.
3. **Core Development** - Integrating Isar for offline storage and Gemini for the AI RAG logic.
4. **QA/Tester Validation** - Running strict verification to ensure all 19 Chapters and 7 Schedules are correctly indexed without hallucination.
