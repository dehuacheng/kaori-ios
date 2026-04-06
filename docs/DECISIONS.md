# Decision Log

> Tracks substantial user instructions and project direction changes.
> Each entry summarizes the user's intent so future sessions have full context.

### 2026-04-05 — Add Chat tab with AI agent SSE streaming

**User intent:** Add a new Chat tab to the iOS app that connects to the kaori backend's agent chat API. The tab should support session management (create, list, delete), SSE streaming chat with markdown rendering, tool call indicators, and memory management in Settings.

**Outcome:** Implemented as 4-tab layout (Home | Chat | + | More). Added MarkdownUI as first external Swift Package dependency for rendering agent responses with code blocks, headers, and lists. Created Agent.swift models, SSEClient for SSE parsing, AgentStore for state management, and 4 new views (ChatSessionListView, ChatView, ChatBubbleView, AgentMemoryView). Added "AI Agent" section to Settings with memory management link.
