# Sorana 🔮📚

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Fgeorgeguimaraes%2Fsorana%2Fblob%2Fmain%2Flivebooks%2Fsorana_tutorial.livemd)

An embeddable RAG library for Elixir and Phoenix. Sorana adds vector search, knowledge graphs, and LLM-driven retrieval to any app with an Ecto repo, without needing separate vector databases or services.

> [!TIP]
> Check out [sorana-adept](https://github.com/georgeguimaraes/sorana-adept) for a complete Phoenix app with the Doctor Who corpus ready to query.

## Why Sorana?

Most RAG libraries are in Python and require HTTP integration. Sorana runs inside your Elixir app:

- **One database:** Uses your existing Postgres with pgvector. No extra infrastructure.
- **Local by default:** Embeddings via Bumblebee (EXLA, EMLX, or Torchx). Swap to OpenAI/Cohere if needed.
- **One process:** Embedders and rerankers as `Nx.Serving` under your supervision tree. Built-in telemetry.
- **Pluggable:** Every replaceable part is a simple behaviour with a default implementation.

## Quick Start

Install with Igniter:

```bash
mix igniter.install arcana
mix ecto.migrate
```

Ingest and query:

```elixir
# Ingest content
{:ok, _doc} = Sorana.ingest("Phoenix LiveView is a server-rendered UI library...", repo: MyApp.Repo)

# Ask questions
{:ok, answer} = Sorana.ask("What is Phoenix LiveView?", repo: MyApp.Repo, llm: "openai:gpt-4o-mini")
```

## Usage Modes

Sorana offers three levels of control:

### Simple Search & Ask
One-call functions with smart defaults: query rewriting, hybrid search, reranking.

```elixir
Sorana.search("query", repo: MyApp.Repo)
Sorana.ask("question", repo: MyApp.Repo, llm: llm)
```

### Pipeline (Modular RAG)
Compose custom steps for full control.

```elixir
Sorana.Pipeline.new("query", repo: MyApp.Repo, llm: llm)
|> Sorana.Pipeline.rewrite()
|> Sorana.Pipeline.search()
|> Sorana.Pipeline.rerank()
|> Sorana.Pipeline.answer()
```

### Loop (Agentic RAG)
Let the LLM decide the search strategy.

```elixir
Sorana.Loop.new("complex question", repo: MyApp.Repo)
|> Sorana.Loop.run(llm: "openai:gpt-4o-mini")
```

## Architecture

```
Your Phoenix App
├── Sorana.search/ask (simple)
├── Sorana.Pipeline (modular)
└── Sorana.Loop (agentic)
    ├── Chunker | Embedder | Searcher | Reranker | Grounder
    └── Knowledge Graph (entities, communities)
        └── Your Ecto Repo (Postgres + pgvector)
```

Everything above the Repo is pluggable with behaviours.

## Guides

- [Getting Started](guides/getting-started.md) — Installation and setup
- [LLM Integration](guides/llm-integration.md) — Configuring providers
- [Pipeline](guides/pipeline.md) — Modular RAG details
- [Loop](guides/loop.md) — Agentic RAG
- [Search Algorithms](guides/search-algorithms.md) — Hybrid search, RRF
- [Reranking](guides/reranking.md) — Cross-encoder, ColBERT
- [GraphRAG](guides/graphrag.md) — Knowledge graphs
- [Evaluation](guides/evaluation.md) — Metrics and testing
- [Telemetry](guides/telemetry.md) — Observability
- [Dashboard](guides/dashboard.md) — LiveView UI

## Development

```bash
docker compose up -d        # Postgres + pgvector
mix deps.get
MIX_ENV=test mix ecto.create && MIX_ENV=test mix ecto.migrate
mix test
```

## License

Apache-2.0
