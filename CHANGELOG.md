# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Deprecations and breaking changes

- **Renamed `Sorana.Agent` to `Sorana.Pipeline`.** The previous name was
  misleading: it described a composed Modular RAG pipeline, not an
  autonomous agent. The new name matches the literature (Singh et al.,
  2025) and conventions in LlamaIndex (`QueryPipeline`) and LangChain
  (`Chains`).

  - **Calls to `Sorana.Agent.*` functions still work** via a deprecated
    facade that delegates to `Sorana.Pipeline.*`. Compile-time deprecation
    warnings will appear. The facade will be removed in 3.0.
  - **Behaviour modules were renamed and are NOT aliased.** If you
    implement custom modules with `@behaviour Sorana.Agent.Reranker`,
    update them to `@behaviour Sorana.Reranker`. This is a
    one-line change. Affected behaviours:
    - `Sorana.Agent.Searcher` → `Sorana.Searcher`
    - `Sorana.Agent.Reranker` → `Sorana.Reranker`
    - `Sorana.Agent.Rewriter` → `Sorana.Pipeline.Rewriter`
    - `Sorana.Agent.Expander` → `Sorana.Pipeline.Expander`
    - `Sorana.Agent.Decomposer` → `Sorana.Pipeline.Decomposer`
    - `Sorana.Agent.Selector` → `Sorana.Pipeline.Selector`
    - `Sorana.Agent.Answerer` → `Sorana.Pipeline.Answerer`
    - `Sorana.Agent.Grounder` → `Sorana.Grounder`
  - The `Sorana.Agent.Context` struct is now `Sorana.Pipeline.Context`.
    Code that pattern matches on the struct module name needs updating.

- **Moved three cross-cutting behaviours out of the `Pipeline` namespace
  into the root `Sorana` namespace.** `Grounder`, `Searcher`, and
  `Reranker` are used by both `Sorana.Pipeline` and `Sorana.Loop` (and by
  `Sorana.search/2` for Searcher and Reranker), so they don't belong
  under `Sorana.Pipeline`. The five remaining step behaviours (`Rewriter`,
  `Expander`, `Decomposer`, `Selector`, `Answerer`) stay under
  `Sorana.Pipeline.*` because they're genuinely Pipeline-specific steps.

      Sorana.Pipeline.Grounder             → Sorana.Grounder
      Sorana.Pipeline.Grounder.Hallmark    → Sorana.Grounder.Hallmark
      Sorana.Pipeline.Searcher             → Sorana.Searcher
      Sorana.Pipeline.Searcher.Sorana      → Sorana.Searcher.Sorana
      Sorana.Pipeline.Reranker             → Sorana.Reranker
      Sorana.Pipeline.Reranker.LLM         → Sorana.Reranker.LLM
      Sorana.Pipeline.Reranker.CrossEncoder → Sorana.Reranker.CrossEncoder
      Sorana.Pipeline.Reranker.ColBERT     → Sorana.Reranker.ColBERT

  Update custom `@behaviour Sorana.Pipeline.Grounder` declarations,
  `config :sorana, reranker: Sorana.Pipeline.Reranker.CrossEncoder`
  entries, and any direct module references. No deprecated aliases at
  the `Sorana.Pipeline.*` level — this is a single hard rename. The
  `Sorana.Agent` facade from the first rename already covers users
  coming from the legacy `Agent.*` names.

- **Renamed pipeline telemetry events from `[:sorana, :agent, ...]` to
  `[:sorana, :pipeline, ...]`.** All eleven Pipeline step spans (gate,
  rewrite, select, expand, decompose, search, reason, rerank, answer,
  ground, self_correct) now emit under the `:pipeline` prefix. The
  legacy `:agent` prefix is no longer emitted at all. If you have
  custom telemetry handlers attached to `[:sorana, :agent, :*]`, update
  them to `[:sorana, :pipeline, :*]`. The metadata keys are unchanged.

### Added

- **`Sorana.Loop`** — Agentic RAG via an LLM-driven tool loop. Where
  `Sorana.Pipeline` composes RAG steps you decide ahead of time, `Loop`
  hands the wheel to the LLM: it picks tools (search, rewrite,
  decompose, answer, give_up) each turn until it can answer or hits
  `max_iterations`. Includes a fallback synthesis step that produces a
  final answer from accumulated chunks when the loop runs out of budget
  without an explicit `answer` call. Emits a single span at
  `[:sorana, :loop, :*]`. See the [Loop guide](guides/loop.md).

## [2.0.0](https://github.com/sonar-hopes/Embeddable_RAG_library/compare/v1.6.0...v2.0.0) (2026-10-19)


### ⚠ BREAKING CHANGES

* **dashboard:** the Ask page URL shape changed from /arcana/ask (with a client-side mode toggle) to /arcana/ask/<sub_tab>. The old URL still lands on the Advanced sub-tab by default, so existing bookmarks keep working.
* module names changed. Custom behaviour implementers need to update their @behaviour declarations from Arcana.Agent.* to Arcana.Pipeline.*. Code that used Arcana.Agent.* still works via the deprecated facade.

### Features

* Add Agent pipeline with context struct ([a1934f8](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/a1934f88fca8f5e87afb537c1610d5b24ce7e661))
* Add Agent.rewrite/2 and consistent :llm option across Agent functions ([299b432](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/299b432b0de73f5986107fd245f64921fe295374))
* Add Agentic Search tab to Dashboard ([e80504a](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/e80504a75ad6fb2df6efb3834ecae57b61fc2988))
* Add Arcana brand text to stats ribbon ([56518c1](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/56518c1df3c2786576b40462bbbd5e994e3a62f1))
* Add Arcana.Telemetry.Logger for easy telemetry logging ([bb64023](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/bb64023b5bd966b676410d6ffdb0e5a495b0031a))
* Add behaviours for all Agent pipeline components ([3b6e330](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/3b6e33087a330a399bdcc98b3d19cdd0a5a819f3))
* Add Build Graph button and mix arcana.rebuild_graph task ([eb510bd](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/eb510bd5256ca862d5947f7a21c5e990dd618cf5))
* add ColBERT reranker using Stephen library ([5edbe87](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/5edbe874597466ab991442d250ee8a9a8d915287))
* Add collection filter for evaluation test case generation ([7732afd](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/7732afdf9ec2e5ba1a90aad8ab8c0e5e4f4e688e))
* Add collection filter to Documents tab ([e7dea14](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/e7dea144d8f5b96865a39984c5574a3f050e5c5e))
* Add collection option to Agent.search for explicit collection selection ([6511683](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/65116836074625bdc1cbecfb50b74266e920912b))
* Add collection routing to Agent pipeline ([2e25b26](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/2e25b260bd7e42679e1ba48bde98c26ba2e46a03))
* Add collection selector to Re-embed and improve displays ([d820151](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/d82015187b65a5eb57ebf3c3bc30327cf8be072a))
* Add collection selector to Rebuild Knowledge Graph ([83b7635](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/83b76356a318b14b8c6491d85c7a2d5757073367))
* Add collections for document segmentation and file upload UI ([b32a44d](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/b32a44d3399725e1262d431381dd7b14ff12a104))
* Add Collections tab to dashboard with CRUD operations ([6a4c373](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/6a4c373c5af45d0a2150a8275e0c4e34e6eed8d8))
* Add community detection maintenance task and UI ([9b7fc53](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/9b7fc5329f69194225106fcfb6e13b0bfab75963))
* Add concurrency, resume and skip to rebuild_graph and reembed_chunks ([566441a](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/566441a3ba3d568c660d3023a20f51f7996c416d))
* Add configurable embedding providers ([92df3b0](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/92df3b03a0ba4118ce3530da68e866b47a5f60bc))
* Add configurable prompts to Agent and ask/2 ([3b13012](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/3b1301296b0ed330bda5d5bfb2e36fa77d7281b6))
* Add detailed stats to Collections page ([85c8adc](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/85c8adc8ce6ec44b36244e4c6eedde25515851fa))
* Add Document/Chunk schemas and mix arcana.install task ([a2e7641](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/a2e764129be8e07bce3a80e7f53322125004e171))
* Add E5 embedding model prefix support ([687e2c0](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/687e2c08faa672a122d3ad5b6a2807287ddec605))
* Add end-to-end answer evaluation with faithfulness scoring ([677e490](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/677e490ca28f63dc0f69460f4009a6f386d2f27d))
* Add end-to-end tests for LLM integration ([ef849f2](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/ef849f236677f1fcf3a16974119d42643c7c7407))
* Add fast Python leidenalg community detector ([b381a26](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/b381a26c95de7405a02e8853805f95a73f16b8f1))
* Add foundation - Chunker and Embeddings with TDD ([d7e6610](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/d7e66108a2d1ea63d7e3198a7155fe2203dfccb6))
* Add fulltext search to VectorStore and wire all modes ([4bda097](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/4bda097c7d57b7e5d15a9dd3883d5ea549301c11))
* Add gate and reason telemetry events to logger ([ffa0bf0](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/ffa0bf0210984638142fe1c2cf5ed772d27c6e1e))
* Add gate/2 and reason/2 for agentic RAG, split agent tests ([4e35452](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/4e35452397885aa271fc0b6c0db28ac13c5094d7))
* Add generate test cases button to dashboard ([2652805](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/265280589d51059bd3a0b326c4e26885b8dd1089))
* Add graph toggle to ingest and fix API key redaction ([64d83ae](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/64d83ae6cd85f9420853290aeb1d7f1e16b74d69))
* Add GraphRAG (Graph-enhanced Retrieval Augmented Generation) ([#7](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/7)) ([00bb820](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/00bb820be54c836a32b81d2e1dee538fe0f788a4))
* Add hierarchical community detection with min_size filtering ([9bb3105](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/9bb3105664388c8bea7b022ea244cc6ecea44755))
* Add hybrid search with vector + full-text fusion ([ff06a13](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/ff06a130f0d6441b73cd9cb9e566b9794188f1bd))
* Add icons to action buttons in Documents and Collections pages ([ab2903f](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/ab2903ff57bda98357236bbaf90ca91cdb966462))
* Add Igniter-powered installer for automatic setup ([61367f3](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/61367f39b7645a5ed3b64b803601dcb894e7c9b0))
* Add in-memory vector store backend with HNSWLib ([54535b2](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/54535b282add5515d951696c0a3722cb05d147a2))
* Add Info tab to dashboard showing all configuration ([335b23c](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/335b23c1632f046b7d0742b8ee7244a113c97907))
* Add Leiden logging and CommunityDetector to Info page ([0741138](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/0741138f975671c79030910a0969d88c8a05ee50))
* Add LiveView dashboard with purple theme ([a506492](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/a506492856a3e0883425bc83e10252f6db650d66))
* Add LLM protocol for flexible LLM integration ([63d26f1](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/63d26f15d50b4b3008cb5fd4ad728a96f0af8f2b))
* Add macro-based router for embeddable dashboard ([94798eb](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/94798eb3df1623fdee096828e9c3ec09f259619a))
* Add mix arcana.graph.summarize_communities task ([dcdb11d](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/dcdb11de7305382b21e5c910bb37f9d87e1478ef))
* Add multi-select collection filter to Ask and Search tabs ([e5709f1](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/e5709f16852323a5c2040b9443f683558109dfa0))
* Add orphaned graph data management to Maintenance page ([b151a63](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/b151a6336ce472799b1eec77c99ad70a4ffb5174))
* Add pagination to graph explorer ([862c1f5](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/862c1f5e6d35a2abec2a48244e771bfdf5b9ddd4))
* Add PDF and document file parsing ([c974536](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/c974536d0fa57ad457c23c67b5f6c8472dec637d))
* Add PDF parser behaviour for custom implementations ([b3aa287](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/b3aa28767c40c1c7285a37c04d531ff2980e7a14))
* Add per-call :vector_store option for backend override ([354fe2a](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/354fe2abbaa5b0e2ccd3ab922f44c653d51faf0a))
* Add pluggable Chunker behaviour for custom chunking strategies ([04972f4](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/04972f4b4715ab7461f9db0b92f25f21e05a0597))
* Add pluggable Selector behaviour for Agent.select ([ee3bc8b](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/ee3bc8b0fc9b5adc433c9d90d6587f83ab8c79cd))
* Add query expansion step to Agent pipeline ([be27d0c](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/be27d0cbc4aa7586acf921d6e05bc21257611de4))
* Add query rewriting with LLM support ([fd526c5](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/fd526c55d610af4a75a58f3d9aa4cec5bce8d052))
* Add question decomposition to Agent pipeline ([95d0d89](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/95d0d89f351be5ac57158843c2c7791c877f69c1))
* Add RAG pipeline with Arcana.ask/2 ([dc71d5e](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/dc71d5e03e0fe3dc30b86d57686cba0b272467f7))
* Add re-ranking step to Agent pipeline ([0448a3c](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/0448a3cdb8818310e0e22976820a89960e4151a8))
* Add Rebuild Knowledge Graph to Maintenance page ([b30b49f](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/b30b49f0eb0fa53f205b52d9ffe74366a77300bb))
* Add release workflow with GitHub-generated notes ([111bf6a](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/111bf6aad8462a872cca8f797d3f6a5912ed3866))
* Add reranker config to dashboard Info tab and EvaluationRun ([0beba3e](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/0beba3ec67a115dca6b62b5709e1da10e0fe1117))
* Add retrieval evaluation system ([fb5d631](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/fb5d6314248d7d7d9f9f31fb19477f0f01676434))
* Add rewriter helpers (expand, keywords, decompose) ([161da88](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/161da886c99e8fd2513edb84633733d0a7fe9a30))
* Add self-correcting answers and consistent :llm option across Agent functions ([2f887c3](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/2f887c373cb9117c4c913b0bfc3c166071ddb38e))
* Add self-correcting search to Agent pipeline ([2cc2029](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/2cc202921627182537050f606f3640c5be81c88d))
* Add Simple/Agentic mode toggle to Ask tab ([857be1d](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/857be1da14a05f6fe35b613f6566b80f1b10a0c5))
* Add single-query hybrid search for pgvector backend ([ef1e451](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/ef1e45106da85ac26d73bf14b5fdc1b6ae65c835))
* Add stats, pagination, and document detail view to dashboard ([35f645a](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/35f645a9b9b8b9ff150f6b14493d16dea0288c40))
* Add swappable GraphStore backend ([#9](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/9)) ([97b04e3](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/97b04e3a54440de31ffd9caabc1871cc70418697))
* Add swappable GraphStore issues from GitHub [#8](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/8) ([305e693](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/305e693dc245e7f8b707d137766fa4c3a087310f))
* Add telemetry events for observability ([170758e](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/170758e3ab845abef7f494b02da64067e98f27e0))
* Add telemetry for LLM calls ([53eb9d0](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/53eb9d0a303408e49753866c4521afc5547ebf17))
* Add telemetry to GraphStore and VectorStore ([c27b586](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/c27b586bd270c840d90440e65bb80bce7e123146))
* Add theta option for faster Leiden convergence ([f56af31](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/f56af31550d776f3639bc997e3a33d319b83a6cc))
* Add tuple LLM config and improve ask return value ([5a5e4e3](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/5a5e4e305037ba037d077636513ebf3ac0d21d21))
* Add Z.ai embeddings and rename Embedding to Embedder ([1cd41c4](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/1cd41c47b9d6632298c8120315e7d96756bf432a))
* **ask:** redesign graph toggle as Graph-Assisted search ([2045fd0](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/2045fd09eb7284397630a9ca9e9c442c361f5107))
* Complete minimal RAG loop with public API ([8a72241](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/8a722412674cb070a02132ec8cf103421019205e))
* **config:** global config defaults and unified opts merging ([fb95531](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/fb955313e43a61d45eeeb55c26479a1c8f3902f4))
* **dashboard:** add dynamic entity type and relationship options at graph_live.ex ([#29](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/29)) ([2868ce3](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/2868ce34d609a513809e97bed3f2b870eb98051f))
* **dashboard:** sub-tab polish and live tracing for Ask ([c9ec3cf](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/c9ec3cf076c7453d61398e6121a2a04f57b955ac))
* Display graph stats in dashboard when GraphRAG enabled ([1f95cf4](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/1f95cf4b71b5a3c6ee7374c9770148d7a1cbac2d))
* Enhance dashboard with search modes and format options ([318235c](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/318235c2a0ed17d908196976d7866b0eff549957))
* Enhance Info page with more config details ([dde8d2e](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/dde8d2e8f3e0522e8e9f41913015ee22e5320210))
* **evaluation:** pluggable retriever and answer correctness scoring ([0274125](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/02741252ebc3a648f12e863770f244514957dcde))
* **graph:** community summary improvements and config extraction ([3faf7da](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/3faf7da1f2255604b13b70863cf22cd725b0fbc5))
* **graph:** GraphRAG Local Search alignment ([1065063](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/1065063cd71569119e0663079332652bc74175e4))
* **graph:** pluggable entity matcher for graph-enhanced search ([aa191d7](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/aa191d7aa8baa3f34936873466b88a5404cbbaf8))
* **grounding:** Hallucination detection via Hallmark NLI ([#49](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/49)) ([a84b11c](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/a84b11c4d8ec100ef35e838116599163af789df1))
* Improve LLM select UI in Ask page ([91aa894](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/91aa894ecfcac0bd1e14c44ce3e5519e9c959da7))
* Improve query decomposition prompt ([8de932c](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/8de932ca697c0994f648453b0483a1cb038d7f10))
* Improve query expansion prompt ([b6b36ef](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/b6b36ef86492d5f9d676ad2c8852532e09ff142b))
* Include collection descriptions in select/2 prompt ([95ef357](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/95ef357a23127811ce9e5e251b285faf88aaa7e3))
* **loop:** Arcana.Loop (agentic RAG) with grounding and tool-call attribution ([287560f](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/287560fd8e3fda697738b4f99cefee9f22e1540e))
* **loop:** per-tool-call telemetry for live tracing ([6eed3ed](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/6eed3ed3dad08e49b9bacfbfa2ab9f2f06606323))
* Make Nx backend configurable (EXLA, EMLX, Torchx) ([#5](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/5)) ([6d410a2](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/6d410a2731300151ac248cde4a11309d072d6122))
* Make PDF support optional ([436c4cb](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/436c4cb9090a151f6834db68f39c83803a2cf4ec))
* Pipeline components respect skip_retrieval flag ([c475afb](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/c475afb91dc597a34aec00df1b9a31cd785e7cc3))
* Replace custom chunker with text_chunker library ([73275bb](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/73275bbdcdf3bb08ead43e4a9011a1cd06f7a46f))
* Restructure Info page with expanded config display ([cd83ff6](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/cd83ff6b3bcf7ae2b4330b8e9b6768e8699fb2b3))
* Save Arcana config in evaluation runs ([9bab271](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/9bab2714ecf665d37214b6f011da8dfc35f276a8))
* **seach:** fix rrf search (graph results and vector results ids were on different format) ([#44](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/44)) ([413409a](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/413409a620ffefe2681001fc56b7d4f9e1c77ecd))
* **search:** local cross-encoder reranker via Bumblebee ([94b4c45](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/94b4c459045d62c83f1cd1d67f725281778992d4))
* Support collection descriptions in ingest/2 ([e375eda](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/e375eda590ef09574a511f00a59148cb55789fe3))
* Support custom module embedding implementations ([dabefd4](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/dabefd47a574b2f5a6a3309f1996834910024c73))
* Support provider_options passthrough for LLM calls ([0280679](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/0280679e10279f4cb432d160b2601c5a92bcc2ee))
* Use req_llm fork with Z.ai thinking parameter support ([a7220b6](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/a7220b6f5840cdca5d61462a5d0e0df2fa587cf9))


### Bug Fixes

* Add collections table to migration template ([253268f](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/253268f4ac4c554902efcf912ae5455244f000f9))
* Add quotes around if expression for YAML parsing ([9febce0](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/9febce00825bfa359687ab34d75d121a4d3055de))
* Add validations to Evaluation Run and TestCase changesets ([1163c04](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/1163c04bf2c7b584d3685dd5447c91ebb70103d3))
* Address Credo issues ([e1ecdb3](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/e1ecdb330a310fde91fccc27983f43d825e51c52))
* Address credo warnings and code style issues ([3212b10](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/3212b106277661aa91a7f96162db3702ee1c0dae))
* Align action buttons in documents table ([2e63e79](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/2e63e7994900af59943891e80f2c27623db7d956))
* Align Search tab collection CSS with Ask tab ([049c26c](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/049c26ca0ae237906009e3c6632a7160ff5625ee))
* **answer_metrics:** strip markdown code fences from LLM judge ([0274125](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/02741252ebc3a648f12e863770f244514957dcde))
* Capture loading state from render_click return value ([090f9eb](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/090f9ebc0719f80099cfd9fa8f395aa2852e7020))
* Center icons in Actions column ([01243bb](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/01243bb8e72f73bccc643aef4130caed21013b07))
* **ci:** add include-v-in-tag to match existing tags ([f710526](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/f7105261923220f2e93fb19b53a5f5686b4ca823))
* **ci:** add last-release-sha to bootstrap release-please state ([c1981bf](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/c1981bf2e1203d1b83b5579fa78b70b8d82dd749))
* **ci:** bootstrap release-please to skip past PR [#6](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/6) ([619b179](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/619b1797b33fd84a66baa2e7de816d0bbe213dc6))
* **ci:** chain hex-publish in release-please workflow ([2cc0239](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/2cc0239a3622cc2a38ad7571cea5b03ba169dcf2))
* **ci:** checkout merge commit SHA when creating release tag ([0c09cf4](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/0c09cf4356552a6625935fdf5057b03d8408c03b))
* **ci:** handle workflow_dispatch and yaml escaping issues ([f7732c4](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/f7732c41b8ae0aaa008dca8c4d2dd1f135cb4657))
* **ci:** match release PR title pattern to existing PRs ([bf6416e](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/bf6416e108a50bc4c3d4b7a2d24b65dc1a505a32))
* **ci:** update release PR label after creating release ([68232d7](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/68232d78690fad292efc6a160a312610e650eff0))
* **ci:** use manifest mode for release-please ([9314a87](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/9314a87a01d1865e6a5fdd0f3043bd2b67149ca8))
* Consistent error handling across API ([6d3ebde](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/6d3ebde3aeae039edc4cf6b688639e000d7fc51b))
* Convert indices to entity IDs in hierarchical community detection ([39c1a25](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/39c1a250ad89b3673ed9214e7dc481141701c30b))
* Correct name in LICENSE to match README ([988ead6](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/988ead61e64bc0e1f17fc4f8a21f3198a5b4aa7f))
* credo warnings in ColBERT test ([5358132](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/5358132a505e89febb57711fed7b433b10f13507))
* **dashboard:** flatten agentic results to fix KeyError on Ask page ([e358e5b](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/e358e5b024f5d7767bdec65a786c7fda932f8d13)), closes [#25](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/25)
* Explicitly set enabled: false in test graph config ([38fb203](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/38fb2033646721fe887ca0f92c4453de732155f2))
* Extract global config tests to separate async: false module ([46eeec0](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/46eeec0a807c6c87b1fab79959c94f443e3161c4))
* Filter out whitespace-only chunks during text splitting ([73fc6c8](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/73fc6c8577ea354ad589fb9d8c02459b41feed0e))
* Fix ask_live template and telemetry logger ([79b09d2](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/79b09d2c927ab4cf35dbf5909d9a469435773c64))
* Fix flaky tests and update README license format ([7a6cce7](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/7a6cce726605ab10a2eea6ae638d37078445c456))
* Fix telemetry.span return value and add collection filter ([3283308](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/32833082bf05a741cfe2f4f856f1d7b2fcd305bf))
* Force GitHub to re-register release workflow ([#4](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/4)) ([a295f1a](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/a295f1a6f69f54fcd587f6a10078b654c64c3573))
* Graph-Enhanced toggle styled as inline checkbox ([c65c87e](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/c65c87ea85032328081ca4413d874ba3308b7f6b))
* **graph:** pass entity metadata to Entity.changeset when upserting it ([#57](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/57)) ([bfd7d1c](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/bfd7d1cd0ec63fe4b8433b60b696f79435621785))
* **graphstore.ecto:** add metadata field to relationship persistence ([#37](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/37)) ([87d5a30](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/87d5a30c8b53811f9be0f9b2168dde0fd3c7f51a))
* Handle doc query param in documents page ([0bbc0cf](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/0bbc0cf40ca0bcfb627dfecf5f30d638fbcb7426))
* Handle poppler_not_available error in PDF ingest test ([6817f4d](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/6817f4db4e8d8583a1d07472717118a681240f5c))
* Improve community summary prompt to avoid generic intros ([9c099ff](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/9c099ff7bc95dc3638195a67b469cfa190248003))
* Improve document detail view styling consistency ([e448657](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/e4486572c8b19bf1736659fe8ca49f202b971821))
* Improve documents table styling ([4a4e6c2](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/4a4e6c28497438a325cdf6df3a21a7741f8cf13b))
* Include model metadata in telemetry stop events ([f0a1eea](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/f0a1eea8e95e10538ed5de1c25d11daa314a77ac))
* Install cmake in CI for hnswlib compilation ([ed1175a](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/ed1175a3a0b41e80be0887b4b3704ea17543299f))
* Join through Entity for relationship counts per collection ([3f90303](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/3f90303c9503a8997b5b823e8581d3f71904815f))
* Lighten rel-type background and add section spacing ([14fc4a9](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/14fc4a9cc4140a58288f5059dd39d46baf988452))
* Lower default chunk_size to 450 tokens for model safety margin ([7cabb17](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/7cabb177384d34e00b775fc682026d2f7762dbae))
* Make Arcana brand text bigger and vertically centered ([4482abc](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/4482abc09bf91b4c25c63e3cc2cc0a217b140675))
* Make EmbedderTest async: false to prevent config races ([ed91b83](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/ed91b8353533bab3baac10a7a2d702c521eb8acd))
* Make evaluation run async to avoid blocking LiveView ([efc70f8](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/efc70f8514b0afc6d8f9544f6a8959b1b7649b0e))
* Make evaluation run async with supervised tasks ([e6999ff](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/e6999ffafc55fbcbfe0582f1e605387e09d7afbf))
* Make file upload dropzone clickable ([155321c](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/155321c8d2e4f3fde3e7a2fe50982cc2521b8571))
* Move collection checkbox CSS to main style block ([dfa6071](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/dfa6071b472c1070f5ddbd71e3405b6153fa3d1f))
* Move DB queries from mount() to handle_params() in LiveViews ([87f2d4e](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/87f2d4eb170e118fe68d22d5998c87a91492ef56))
* Move Repository to info grid as card ([330fbdb](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/330fbdba31f6eea5a6e2c788d59cede727f7c865))
* Prefix unused variables with underscore in tests ([e27b1d1](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/e27b1d1ec19cf3a80b6a40d4b73eb1987d29aee9))
* Quote if expression to fix YAML parsing error ([057bff3](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/057bff3b288840bed0e83bf8049cc886a82021c8))
* Redact sensitive keys (api_key, token, etc.) in Info page ([bb7fff4](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/bb7fff4717824ecf6166e4c527e9b59b48c36bd3))
* Remove arcana-actions class to fix button alignment ([9dce9fa](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/9dce9fa5a1df0390f4d8988117f2e91044f59434))
* Remove borders from Documents page icon buttons ([deaf035](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/deaf0351e57c6410ddad31ccf188d730aa7ff5e1))
* Remove elixir_make override and update hnswlib ([e8d381a](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/e8d381a97092e5ff29bea679429e674f73607680))
* Remove invalid collection_id queries from Relationship schema ([38c25e8](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/38c25e8925383202487a47910f7ed5f01e9406bf))
* Remove long transactions from reembed to prevent DB timeout ([75dd8d4](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/75dd8d4afb70e4abd91b1ecfd45c9b8fec69c31d))
* Rename workflow to force new GitHub registration ([40a199b](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/40a199b2789f779a6ab29d406fdf004444c95b03))
* Reorganize Build Graph checkbox layout ([4018efa](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/4018efa9d85173dadfc219bbe7287829381729ce))
* Resolve credo warnings for CI ([9018120](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/901812045d6f27fa1d5ee82c683553d56eee6fde))
* Resolve DBConnection timeout errors in CI tests ([f0ba922](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/f0ba9221e0f6df4bc46f7dd4ff11c80c772eb3d9))
* Resolve NER serving race conditions and test isolation ([3e1a6ad](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/3e1a6ad3d6242b3459086367d8f39d93e08528fd))
* Set minimum pool_size of 20 for CI environments ([944c303](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/944c303d5abca6a19a7d85819b922655d6207198))
* Set MIX_ENV=test for CI database setup ([5d98875](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/5d98875c2b7927bed8e8d504b128174fd4212fe5))
* Show graph stats on collections page when data exists ([9fb9873](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/9fb987341b4c8616582e2a73e7e90e8943a34d13))
* Specify postgres user in CI health check ([93257dd](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/93257ddd6754a35e205129ef7525d9cffd6e968f))
* Stabilize async tests with VACUUM on startup ([62d29d9](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/62d29d91c45a9b6c513213dfaaf6df62b8ac6bc6))
* Start host app in mix arcana.reembed task ([f66ecec](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/f66ecec88859373f93782348279a42b1e973a466))
* Strengthen community summary prompt to prevent generic intros ([f9fc9fe](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/f9fc9fed556ca6b2c18442de5898ae6819937af7))
* support all forms of llm configuration on maintenance.ex ([#22](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/22)) ([e19fad8](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/e19fad8c118dcf36416b265a3ebc9b8e3ccdca5f))
* Trim leading/trailing whitespace from LLM answers ([f852841](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/f852841a63a2190afd33e9b05c54f0d7e1e073c0))
* Update arcana.install to use correct Embedding.Local module ([240308f](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/240308f2b775cc5cc646e34ae19d87cd02107971))
* Use apply/3 for optional dependencies to avoid compile warnings ([d824e6f](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/d824e6faf27cdd34efb39846f1b3859febca0c6b))
* Use async: false for telemetry tests ([932a49a](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/932a49a63442926e416335c9fc123447afb8288f))
* Use plainto_tsquery for safe fulltext search input ([faf1441](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/faf14410081e5aea96d7885aad0fa8a51f29c9aa))
* Use text-align for Actions column centering ([c5e45db](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/c5e45db6587ba388447241395f905dbdf89fc451))
* Use trash icon for delete button in test cases list ([e320b6e](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/e320b6ed0a3bb1a8ff09cc2c3e81a1a2d03700ce))
* Validate UUID format in Chunk changeset ([c1e29a6](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/c1e29a65c392e180cfc8af9826014b961f998d11))


### Miscellaneous

* Add Apache 2.0 license ([22e9fd4](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/22e9fd49b1bc591ed62dcb69883520a3783837eb))
* Add credo, GitHub Actions, and release-please ([c77a056](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/c77a056d15793a9c3f545bd72ecb572114774e83))
* add dependabot for daily dependency updates ([#11](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/11)) ([6791a6a](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/6791a6a2a40c492e30f12ddad70463f47b64b08e))
* add fallback section for non-conventional commits in release-please ([7c4cc9c](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/7c4cc9cdc0641f698c5f5e85e1c15ac126dbb56e))
* Add hex.pm package metadata (licenses, links) ([0dd811e](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/0dd811ec588250726910f72ed494cd1c63c10bc5))
* **beads:** remove beads issue tracking system files ([7b4dfd7](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/7b4dfd7a756fbda6316aae7d0b4a6195bf1efa00))
* **deps-dev:** bump credo from 1.7.15 to 1.7.16 ([#34](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/34)) ([7791b52](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/7791b52c5249efa5ccac9d37100981399ed39b67))
* **deps-dev:** bump credo from 1.7.16 to 1.7.17 ([#51](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/51)) ([9cace47](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/9cace47fbccae7bd84cc325431490a44f2049eb2))
* **deps-dev:** bump ex_doc from 0.39.3 to 0.40.0 ([#28](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/28)) ([129fb91](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/129fb919a08b69db3a2c615479ca3fb3e0017099))
* **deps-dev:** bump ex_doc from 0.40.0 to 0.40.1 ([#38](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/38)) ([7150373](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/7150373c350b47501fff420836fed7db59ff4750))
* **deps-dev:** bump floki from 0.38.0 to 0.38.1 ([#62](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/62)) ([74f5313](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/74f5313f0d6ea72652ea9b8df33b8780210b964e))
* **deps-dev:** bump lazy_html from 0.1.8 to 0.1.10 ([#42](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/42)) ([5f46e39](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/5f46e39af3e0e5b862460dcd19f5ec9e743d1752))
* **deps:** bump actions/cache from 3 to 5 ([#13](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/13)) ([6cd7ea6](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/6cd7ea672e1d257ac620f92e288c9d389de06023))
* **deps:** bump actions/cache from 5 to 6 ([b8a3f8f](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/b8a3f8f5ad6f0deb467167c67bac939c261920a5))
* **deps:** bump actions/cache from 5 to 6 ([a7dd273](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/a7dd2730b03572ac3ed0d4b54333fc41ed32d66e))
* **deps:** bump actions/checkout from 4 to 6 ([#14](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/14)) ([14ab7e3](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/14ab7e347c941e8de8b530f6a855edfb29b43158))
* **deps:** bump amannn/action-semantic-pull-request from 5 to 6 ([#12](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/12)) ([cee18f7](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/cee18f7f2b85dbc9dc85eecc8842041159964d8b))
* **deps:** bump ecto_sql from 3.13.4 to 3.13.5 ([#50](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/50)) ([6c8dbdf](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/6c8dbdf4d6a8e3229495859b9ae75941a5a5c773))
* **deps:** bump hallmark from 1.0.1 to 1.1.0 ([5ca2012](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/5ca201213c0f1daf1c921f4d967ad4c8f6013d83))
* **deps:** bump hnswlib from 0.1.6 to 0.1.7 ([#20](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/20)) ([c465597](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/c465597236427ff4a900a96fa87d0a3326bfd0ac))
* **deps:** bump igniter from 0.7.0 to 0.7.1 ([#31](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/31)) ([2fb2058](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/2fb2058a35903c0bc071ccc46f65b83d04afe04d))
* **deps:** bump igniter from 0.7.1 to 0.7.2 ([#36](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/36)) ([3c5095e](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/3c5095e88a5fd7c09a986ed9383ec36818a1a969))
* **deps:** bump igniter from 0.7.2 to 0.7.3 ([#54](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/54)) ([4a1356f](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/4a1356faa2b41c0f22adbe8b4c79334f102f3828))
* **deps:** bump igniter from 0.7.3 to 0.7.6 ([#61](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/61)) ([c48a1cd](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/c48a1cd859460b23f8a18446632e9f94f19f4602))
* **deps:** bump phoenix_live_view from 1.1.19 to 1.1.20 ([#21](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/21)) ([c216cf9](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/c216cf95da7daaf7b9f2661c62ad6993ac29d8e8))
* **deps:** bump phoenix_live_view from 1.1.20 to 1.1.22 ([#35](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/35)) ([9f67d2d](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/9f67d2d782919b17a78e9dba695cac9ce196a220))
* **deps:** bump phoenix_live_view from 1.1.22 to 1.1.24 ([#41](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/41)) ([6be8352](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/6be8352c3d132cb97ec0d901168544807b5a7d63))
* **deps:** bump phoenix_live_view from 1.1.24 to 1.1.25 ([#47](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/47)) ([f6aec1e](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/f6aec1e17a0bde6ba1cb666162f700206e739562))
* **deps:** bump phoenix_live_view from 1.1.25 to 1.1.26 ([#53](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/53)) ([622acca](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/622accac6f86e00b86801de9998c8f76459eca65))
* **deps:** bump phoenix_live_view from 1.1.26 to 1.1.27 ([#59](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/59)) ([5fe6666](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/5fe66668473a53c49e69d90f51ab19652ee2f013))
* **deps:** bump postgrex from 0.21.1 to 0.22.0 ([#19](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/19)) ([f87832d](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/f87832d80723d44abbef60da47b279ae65554c16))
* **deps:** bump req_llm from 1.2.0 to 1.3.0 ([#30](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/30)) ([899b27e](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/899b27e48723a65145b21f0ce11bcefe5a9a2ae1))
* **deps:** bump req_llm from 1.3.0 to 1.5.1 ([#40](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/40)) ([86802f5](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/86802f5363a918ca52fc697dea2dfe0b9aac90ec))
* **deps:** bump req_llm from 1.5.1 to 1.6.0 ([#45](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/45)) ([ac189ec](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/ac189ec330f753fc87541ef8883a930c3ab2c129))
* **deps:** bump req_llm from 1.6.0 to 1.7.1 ([#60](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/60)) ([b41d93d](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/b41d93deb01b3297f3454fdeb7f5255b072bf089))
* **deps:** bump req_llm from 1.7.1 to 1.8.0 ([#63](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/63)) ([6e9dc6c](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/6e9dc6c60724b445253d17b521c1c6ce3bb2f687))
* **deps:** bump text_chunker from 0.5.2 to 0.6.0 ([#18](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/18)) ([a0887d4](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/a0887d487458add6c3047342b96ef9c019460754))
* **deps:** update lockfile to latest compatible versions ([0f53bb0](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/0f53bb07958389e6f03570d1c08b1d43737935bc))
* **deps:** use released stephen package from hex ([#16](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/16)) ([19dcec6](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/19dcec68edc4fe785324b3282b1aabd5e83add1d))
* Disable credo apply check for optional dependency files ([e82b47f](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/e82b47f572fe9cf86ef161af67ad59f65ecc6d30))
* Enable always-bump-patch for releases ([cbfb266](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/cbfb2666c6576de71e2846c317e6bb0a87e2d0d7))
* fix credo --strict findings to unblock CI ([305c4a1](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/305c4a1582c198a3bdcfdb1d85b7e4cfda708b8f))
* Fix formatting ([ca08eeb](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/ca08eebdeb41eeaaba9f5e63bd7bc239d96774a8))
* Fix formatting and add Elixir 1.19/OTP 28 to test matrix ([c438b90](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/c438b90eeac61396de000a1c24929fc29636f7dc))
* **main:** release 1.0.0 ([#1](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/1)) ([0e74fb3](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/0e74fb382ca903c85a795757d2020424ed1b538c))
* **main:** release 1.1.0 ([#2](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/2)) ([8dbe565](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/8dbe565813199b82775c3a126ae85bb084997169))
* **main:** release 1.2.0 ([#6](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/6)) ([63fc627](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/63fc6279d54e52f791b2298cf090e4762faa150f))
* **main:** release 1.3.0 ([#17](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/17)) ([eb97746](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/eb97746e391e503abd5f35547b5aa91f2340bc67))
* **main:** release 1.3.1 ([#23](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/23)) ([49e473c](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/49e473c4acdd25264361fb0493740ce553aae711))
* **main:** release 1.3.2 ([#24](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/24)) ([736ef21](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/736ef21139187495f340708278e0b67211797ce9))
* **main:** release 1.3.3 ([#26](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/26)) ([87a3320](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/87a3320416d91c22f1b181d7596ba446e61eb6ee))
* **main:** release 1.4.0 ([#27](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/27)) ([6982c88](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/6982c880b8bfbd323bd3d4a37d81d7f0fcda392f))
* **main:** release 1.4.1 ([#32](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/32)) ([609b956](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/609b9562cca2dcc3714604ff23bbeae370f51fd0))
* **main:** release 1.5.0 ([#43](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/43)) ([558a9ab](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/558a9ab941b95254ca4e02f4d5581d58e7f2788b))
* **main:** release 1.5.1 ([#46](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/46)) ([b9f5260](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/b9f52608ee22816776d8c8d81e0d17ebea8e0681))
* **main:** release 1.5.2 ([#48](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/48)) ([db30d0e](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/db30d0e70346904cae94ca56fe93c28abc2d7162))
* **main:** release 1.6.0 ([#52](https://github.com/sonar-hopes/Embeddable_RAG_library/issues/52)) ([a8703a1](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/a8703a19af8bbdbaa60dc0d7e2d340dfd179e65b))
* Merge all livebook tutorials into arcana_tutorial.livemd ([4a32d14](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/4a32d14b7ef20b23eaa4702efabb46355ab438a8))
* Merge livebook/ and livebooks/ directories ([9d84379](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/9d84379a4498c164a8dfba51bf171173e15f471d))
* Remove completed design plans ([081b5ba](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/081b5ba6975e9d44f5f874aa7eeb47ee4b46fa9f))
* Remove remaining Z.ai embedder references ([698964f](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/698964feb8367f7f102ffeec17a8d831d05a4c07))
* Remove unused .arcana-actions CSS class ([195aa0f](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/195aa0f4dc91d19ad0c0dcf53751e2c164f3af2c))
* remove unused on-release workflow ([1894db5](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/1894db528314d6a16b26afe2183a1dee5550adb8))
* Run mix format ([bbfb6c8](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/bbfb6c8ffb561190846c7206a210e33c89cbd12f))
* Switch hnswlib from GitHub to hex.pm release (0.1.6) ([b880539](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/b880539ddbe09fae9a774abcc579c1aa448468a6))
* trigger release-please ([d0c1356](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/d0c1356cbc5c64a3108d5296bb7098c271fab786))
* trigger release-please ([7062d93](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/7062d933beb1bb13d4fc8d3a18de864ee0e80e27))
* trigger release-please ([98978c7](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/98978c7eb90d8cb46c78666d932c43d7f5bd11c3))
* Update credo 1.7.15, ecto_sql 3.13.4 ([d1c1fba](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/d1c1fba06ad55290447e10fbd30e5ded14fee920))
* Update leidenfold to 0.3.2 ([a65783d](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/a65783ddd9ee0dd9bf78311f00be99d202514a7b))
* Update req_llm to released version 1.2 ([55cad58](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/55cad589f7c1fb57408628210d73b25015075ea3))
* Use proper Elixir/OTP version matrix in CI ([44d21c8](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/44d21c866d313148a2a567b18c6b1a793f370b6f))
* Use upstream req_llm with thinking parameter support ([90d4889](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/90d488972e1d0182885e1520dedf964c06b06911))


### Documentation

* Add agentic RAG design document ([1a06eaf](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/1a06eafbc095c93cf179f102b31e93b4494ed4c6))
* Add CHANGELOG.md for v0.1.0 ([ad1bfb0](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/ad1bfb022d11ae68705e40fb3943821d2229ead0))
* Add chunking options to README ([05b76b6](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/05b76b69d5e98753a629ee1547fbce532c7698ad))
* Add comprehensive embedding model documentation ([ae12831](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/ae12831ff06e8112b04046710380a52ad6865629))
* Add comprehensive README with usage examples ([8d11ab9](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/8d11ab97e2f09d7625ab7546c933745867906979))
* Add copyright notice to README ([d793294](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/d7932944ee54e6b3f5f52228a49dd6cd9ce53e2d))
* Add custom implementations examples to guides and README ([c638fc7](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/c638fc723a81caffa0f2e89dbcca48ba3bff9093))
* Add custom VectorStore behaviour documentation ([240f507](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/240f507a5f7771eb729eaa1771e6b62485f5c9d7))
* Add E5, TurboPuffer, ChromaDB to roadmap ([44ad082](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/44ad082387ad797ca87332b53160906e46abe07f))
* Add embedding providers section with custom embedder example ([18e9dad](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/18e9dad612f8b1aa0ad7625ac52312071af7b477))
* Add emojis to Arcana title 🔮📚 ([2d7a0ed](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/2d7a0edc914ef81a22021ceb1bb741324fb1746d))
* Add end-to-end answer evaluation design ([7e97b26](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/7e97b2671c2d8c9a1c89b98282e89971a1d77494))
* Add Evaluation section to README and update guide ([de75c91](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/de75c91d94855cafa5fbada9d6856961ad8bf7d0))
* Add file ingestion, collections, and PDF support documentation ([81553ef](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/81553ef68455c6ffca439e93a0d5e1df3a0402af))
* Add guides for evaluation, reranking, agentic RAG, and dashboard ([7917b68](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/7917b68dee5c13b7f8cbbd917151f7797e1ea9a5))
* Add guides for getting started and LangChain integration ([2e0659a](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/2e0659a9befefb2fba0e3b11ddd87340e648b7af))
* Add hybrid search weight options to documentation ([4d8e34c](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/4d8e34c62d673e59536b2279dbc5d45fdac71138))
* Add HyDE and GraphRAG to roadmap ([8aa90b3](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/8aa90b3f6cb1694afc29c8e4562a6cfce600d47e))
* Add instructions for changing embedding models ([87f991d](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/87f991da4a7f6892557eb1a4339b1fb4de1d0929))
* Add Livebook tutorial for Arcana with Memory vector store ([3f692f6](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/3f692f63ee625dd8d43a5fdf671a29f56718d2c4))
* Add LLM configuration section to README ([d33184d](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/d33184dcdb484d4a8e5cce92c42a6747ddb9f383))
* Add Maintenance Tasks section to GraphRAG guide ([0388d93](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/0388d935fc17950794394b0c7cfe2a87099b87db))
* Add PDF parser configuration documentation ([8863fbb](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/8863fbbdb3644fe87488d9c1347055d3e20ae057))
* Add query expansion documentation and livebook tutorial ([7cc30e3](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/7cc30e340d75911ac412bfdabc5dbcdb653af002))
* Add re-ranking documentation and livebook tutorial ([2b7e645](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/2b7e64536217cb295655bfbdaa4dfd279effc55b))
* Add reference to arcana-adept example app ([6690808](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/6690808a2778bff57686b3bec748a6ccca7b7e2a))
* Add search algorithms guide explaining Memory and PgVector backends ([b1d17ca](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/b1d17ca6a9533b8806efa49d2c430e68cac6f99c))
* Add telemetry guide and improve observability docs ([be67469](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/be674699a1490256f0f1db121946b29b513ab787))
* Break down Agentic RAG into implementation phases ([6c091f5](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/6c091f50b0107ae40894c5f7ebf8227cef017530))
* Clarify README supports both simple and agentic RAG ([db0ab37](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/db0ab37a40f965441345d075c8e9f41582b166a3))
* Fix ex_doc warnings in guides ([557aa9b](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/557aa9b73bc67911201823dde3974f68b2afe982))
* Fix incorrect guide references in getting-started.md ([1e37b31](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/1e37b3120143c100cd3877dd06e9761df598dd51))
* Fix license to Apache 2.0, add re-ranking to roadmap ([68041e4](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/68041e4a306c1bda5ac767e6003e35c72826357b))
* Fix numbered list in setup instructions ([7272b23](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/7272b239de45072fdbee7d4d08d0e6f55ca51d12))
* Fix outdated module names and reorganize README ([1870e2c](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/1870e2ce285ae4a5b0f304a35aa2389fce8c2be5))
* Improve README with search modes documentation ([628755c](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/628755c01d9749bbab90605a63d8a05f77a62d97))
* Mark Agentic RAG as complete in roadmap ([c55c97d](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/c55c97da3cfcd0a8d108136b3fe9d2f75e259e1d))
* **readme:** align architecture diagram to uniform 83-char width ([7f730a1](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/7f730a134088eeaf59606bb83a456159c4022780))
* Restore manual installation steps to README ([319d54a](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/319d54a47f265ab0bc37de1f5fe6e9b495d133f5))
* Simplify installation with mix igniter.install arcana ([1f71995](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/1f71995c69d21bf5eaa966032bff4840728fb755))
* Simplify README and enhance Agentic RAG documentation ([611301e](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/611301e4e8850696769fb5377559fc5436d50b4e))
* Update 'How it works' section with current architecture ([b2c1c2c](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/b2c1c2c6057524719a6d447deea526dc269a1270))
* Update arcana version to ~&gt; 1.0 ([94658bb](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/94658bb4bd528c1413f18aa0be31d17caf084750))
* Update dashboard guide to reflect page-based navigation ([f31d307](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/f31d307e04e5de590738850c6479e5571615b1c1))
* Update documentation for GraphStore and VectorStore backends ([eb2cb26](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/eb2cb266229fc8dcd44f91f52518a6f512de5663))
* Update features list with all current capabilities ([50966de](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/50966def835afec701654a5aa31ad03f76ff5b3e))
* Update getting-started guide installation section ([1fb2486](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/1fb248621f766bb692a2e75f3d49ea29d7a6d69a))
* Update LangChain guide for protocol-based approach ([8e704fc](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/8e704fc8ce4d80fe64339a2edbcf98c498a56c58))
* Update README with fulltext search and per-call override ([c66f5e8](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/c66f5e861cdb69bf302c0f31fdd75da7c49d3d27))
* Update README with hybrid search mode examples ([c43a97c](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/c43a97cef44eafa348f61ae28daca7af84d8abfa))
* Use GitHub TIP alert for arcana-adept reference ([552d1bf](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/552d1bfc4fed718f689f4e2d5c1e589abd7dc512))


### Code Refactoring

* **ci:** remove redundant if from mark-release-tagged ([2fbe285](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/2fbe2853b3d43188c5b9b7b75d6ea0400d5b1179))
* **ci:** use extract-version action ([6ed93f5](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/6ed93f59785784d3b409e90257a7c4dd07155daa))
* **ci:** use mark-release-tagged action ([e97a67d](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/e97a67dd7026d727bac7a37da1fa359a31cfe45c))
* **ci:** use release-please for GitHub releases ([ee9ed3b](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/ee9ed3b82f001409f83b203c4228c855e610932e))
* **ci:** use shared workflows from georgeguimaraes/workflows ([8dc2a8d](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/8dc2a8d38ea1803434f37a2d42758d866f608b58))
* Convert embedding system from protocol to behaviour ([2b91354](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/2b91354e55fd0b5908e6030fd0d69717ae123041))
* **dashboard:** Ask sub-tabs, Evaluation retriever, Info sections ([dc5ca9a](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/dc5ca9ae097ce1075de5a6b1557883a505a4fb1f))
* Extract build_scores_map to fix credo nesting warning ([c7c77ee](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/c7c77ee2a3c4af8ddcd6a03ee31973e4b86e4b4f))
* Extract helper functions to reduce nesting and complexity ([d26d443](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/d26d443e46d5272d0e43e46554e7926b2069dba1))
* Extract helper functions to reduce nesting depth in Memory VectorStore ([7f24aea](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/7f24aeaeddb76231fb049db65b1cee32a6d82328))
* Extract model dimensions to map to reduce complexity ([320e6c9](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/320e6c9c597638bef6b18d6e2030a24afcf81058))
* Extract nested functions to fix Credo issues ([7ead72a](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/7ead72a5e40acdb283857d25d039f9a429b34006))
* Fix all credo --strict warnings ([39e5860](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/39e5860c6bc8866e34073d772b6835130a3ed817))
* Fix credo issues in agent.ex ([68c48bd](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/68c48bdc32cae68056c9a282b33d97dceb8cd4cc))
* Group handle_call clauses together in Memory store ([a3c1132](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/a3c1132f1532f9321b9377acba1bdd5938a12919))
* Improve answer prompts for more natural responses ([eead385](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/eead385fe69fb78c5142e796b83327e5e2938628))
* Make Agent.new repo and llm optional with config defaults ([9a3fb6e](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/9a3fb6e90840a9d9aa3fb8871175cabae6cb7cf1))
* Make all tests async except telemetry ([6a455c0](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/6a455c04770ee044aa7519f34d79849954696df2))
* Remove merge_defaults helper from Arcana module ([6476f30](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/6476f30586152948cad8e16fd93b5e5f5307a277))
* Remove typespecs from codebase ([32d5e01](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/32d5e0137b5629a62ad46b5fc2691a915faf6226))
* Remove Z.ai embedder and enhance reembed to rechunk documents ([4280f8f](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/4280f8f52f666c96f045c194563d178c4256dd6a))
* Rename Agent.route/2 to Agent.select/2 for clarity ([161e4f4](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/161e4f49776b9e847a8b7f85dc733ff43213e17e))
* Rename Agentic to Ask tab, add tab descriptions ([225c631](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/225c631316dd998b8ef6ff6d4ca5dc81e5209520))
* rename Arcana.Agent to Arcana.Pipeline ([495b588](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/495b58825cb08ddc7e821737b48e852a772ddfef))
* Rename config key :embedding to :embedder ([be6dbb2](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/be6dbb26107d8bd6707d57808e18e20e31d43efe))
* Rename Search tab to Retrieve ([c8136cb](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/c8136cbf5f3afbe7ee65cdd172ecb035282f7cd7))
* Replace ex_leiden/leidenalg with leidenfold for community detection ([9b3e900](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/9b3e9007d1a231bd52d6179beb7ce08281971209))
* Replace LangChain with Req.LLM for LLM integrations ([e9c3998](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/e9c3998d3f814327949997b671a3eb800830b56b))
* **reranker:** batch LLM reranking into a single call ([42141a0](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/42141a042ca0a4d76eea8d1c7d1c1e1d52143acb))
* Simplify Arcana.LLM with shared helper module ([86cc142](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/86cc142b51fd004a79e42a9d8f43b706c88a91cf))
* Simplify merge_defaults in Arcana module ([22c9822](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/22c98221f1c73fba257bd1a51abe3aac63233e98))
* Split dashboard into separate LiveView modules ([ece2998](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/ece2998288b5aea6d9445a6bc01b6d6239a44660))
* Split monolithic dashboard into separate LiveView pages ([f48415e](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/f48415e4b006c14587a2abeeb9d3ba4b09180ff1))
* Switch from Jason to built-in JSON module ([e6aed89](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/e6aed89dc52cfd5f7b3977ce9c7a59d67affdf8b))
* Use Enum.map_join and Enum.empty? per credo ([44abd41](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/44abd412b699c30b8e186d0d2d0ae524f54bdbe0))
* Use leidenfold native hierarchical detection ([e9b9c99](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/e9b9c998562d95a67852970ee7f87252c84d1463))
* Use strings for collection names consistently ([95a78b9](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/95a78b96835d652452c5d5093625c157cfb70af6))
* Use TaskSupervisor for dashboard async operations ([3eaa3c4](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/3eaa3c433f60196389f5fbad7931dcdf6271e53f))


### Tests

* Add tests for Chunker.Custom module ([af75b1a](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/af75b1ac8cd2148b2240a47db7937b58982e9cf0))
* Enable async: true for all test files ([7a342f5](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/7a342f5a96c2ba253b01f7459cae9796b750360b))
* Fix pipeline test to use proper word overlap for mock embeddings ([e3fa154](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/e3fa15430c6510d98c38e47150c7e4b52685ff61))


### Continuous Integration

* Exclude memory tests from CI ([9aab795](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/9aab7952ebffd5c4b336677a777642b423284fc3))
* Tag memory tests in vector_store_test for CI exclusion ([9084573](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/9084573c53e32463035610dbc028a11866504414))


### Performance Improvements

* Optimize list_entities query with subqueries ([20f41a2](https://github.com/sonar-hopes/Embeddable_RAG_library/commit/20f41a29e4dff9c495f9666790e20e37448b5a35))

## [1.6.0](https://github.com/georgeguimaraes/sorana/compare/v1.5.2...v1.6.0) (2026-03-04)


### Features

* **ask:** redesign graph toggle as Graph-Assisted search ([98347ef](https://github.com/georgeguimaraes/sorana/commit/98347efd4b3a479cdbb3a4fbf339ca1895cbe828))
* **grounding:** Hallucination detection via Hallmark NLI ([#49](https://github.com/georgeguimaraes/sorana/issues/49)) ([de1b37f](https://github.com/georgeguimaraes/sorana/commit/de1b37f95fe4f11d6e92d202284e6bafd9b32505))


### Miscellaneous

* **deps-dev:** bump credo from 1.7.16 to 1.7.17 ([#51](https://github.com/georgeguimaraes/sorana/issues/51)) ([4ce74a7](https://github.com/georgeguimaraes/sorana/commit/4ce74a734927f23b2d5e02898adf39fef4cc0ea1))
* **deps:** bump ecto_sql from 3.13.4 to 3.13.5 ([#50](https://github.com/georgeguimaraes/sorana/issues/50)) ([e2a6be7](https://github.com/georgeguimaraes/sorana/commit/e2a6be7834ebc94d59ba4cf28caf7c8aea3b100b))
* **deps:** bump hallmark from 1.0.1 to 1.1.0 ([4f8b617](https://github.com/georgeguimaraes/sorana/commit/4f8b617631eff4d986a0fb9850f16c89ba7aa63b))


### Code Refactoring

* **reranker:** batch LLM reranking into a single call ([f59869d](https://github.com/georgeguimaraes/sorana/commit/f59869d80a2952453d0a9641e77677b0ecd073f0))

## [1.5.2](https://github.com/georgeguimaraes/sorana/compare/v1.5.1...v1.5.2) (2026-02-27)


### Miscellaneous

* **deps:** bump phoenix_live_view from 1.1.24 to 1.1.25 ([#47](https://github.com/georgeguimaraes/sorana/issues/47)) ([6fb0a0a](https://github.com/georgeguimaraes/sorana/commit/6fb0a0a5be8d10acf58348070f335106419608c0))

## [1.5.1](https://github.com/georgeguimaraes/sorana/compare/v1.5.0...v1.5.1) (2026-02-20)


### Miscellaneous

* **deps:** bump req_llm from 1.5.1 to 1.6.0 ([#45](https://github.com/georgeguimaraes/sorana/issues/45)) ([1913830](https://github.com/georgeguimaraes/sorana/commit/1913830d1edd229cf9e9d000944ad1f4e8b086cd))

## [1.5.0](https://github.com/georgeguimaraes/sorana/compare/v1.4.1...v1.5.0) (2026-02-19)


### Features

* **seach:** fix rrf search (graph results and vector results ids were on different format) ([#44](https://github.com/georgeguimaraes/sorana/issues/44)) ([f8c76f5](https://github.com/georgeguimaraes/sorana/commit/f8c76f54da2164c6921f3ee276e388d2654f296b))


### Miscellaneous

* **deps-dev:** bump lazy_html from 0.1.8 to 0.1.10 ([#42](https://github.com/georgeguimaraes/sorana/issues/42)) ([e3ac07c](https://github.com/georgeguimaraes/sorana/commit/e3ac07c61bee19c11f411ab1531ca63bec0dc4b1))
* **deps:** bump phoenix_live_view from 1.1.22 to 1.1.24 ([#41](https://github.com/georgeguimaraes/sorana/issues/41)) ([7b4be4f](https://github.com/georgeguimaraes/sorana/commit/7b4be4fe0ae95f5484296dea08bdefba3e7ae450))

## [1.4.1](https://github.com/georgeguimaraes/sorana/compare/v1.4.0...v1.4.1) (2026-02-17)


### Bug Fixes

* **ci:** chain hex-publish in release-please workflow ([6dbe46c](https://github.com/georgeguimaraes/sorana/commit/6dbe46c973663d915b92191b7f72f607f14ca592))
* **graphstore.ecto:** add metadata field to relationship persistence ([#37](https://github.com/georgeguimaraes/sorana/issues/37)) ([30483ce](https://github.com/georgeguimaraes/sorana/commit/30483ce5c4ee4c00bc98301d75d0abad55161d6f))


### Miscellaneous

* **deps-dev:** bump credo from 1.7.15 to 1.7.16 ([#34](https://github.com/georgeguimaraes/sorana/issues/34)) ([81d7849](https://github.com/georgeguimaraes/sorana/commit/81d78498cbeb5b28d78d5169484aea6821349e95))
* **deps-dev:** bump ex_doc from 0.40.0 to 0.40.1 ([#38](https://github.com/georgeguimaraes/sorana/issues/38)) ([30931fb](https://github.com/georgeguimaraes/sorana/commit/30931fb556f62175b8e5dae811d8fb28aa38b284))
* **deps:** bump igniter from 0.7.1 to 0.7.2 ([#36](https://github.com/georgeguimaraes/sorana/issues/36)) ([2f9e025](https://github.com/georgeguimaraes/sorana/commit/2f9e025b80249bcf413f8ffbb90d00caf351fc7f))
* **deps:** bump phoenix_live_view from 1.1.20 to 1.1.22 ([#35](https://github.com/georgeguimaraes/sorana/issues/35)) ([f44e877](https://github.com/georgeguimaraes/sorana/commit/f44e877f6d694d6815f55c13163f02cdb536a557))
* **deps:** bump req_llm from 1.2.0 to 1.3.0 ([#30](https://github.com/georgeguimaraes/sorana/issues/30)) ([09ce949](https://github.com/georgeguimaraes/sorana/commit/09ce949c091b8aa51aae9a57e232263f533388e4))
* **deps:** bump req_llm from 1.3.0 to 1.5.1 ([#40](https://github.com/georgeguimaraes/sorana/issues/40)) ([0dfa8d7](https://github.com/georgeguimaraes/sorana/commit/0dfa8d774215d59495b292ff61b0d3c05b1c7262))
* remove unused on-release workflow ([df5ff15](https://github.com/georgeguimaraes/sorana/commit/df5ff156e6972574ad6510f2b66855838c5d6824))

## [1.4.0](https://github.com/georgeguimaraes/sorana/compare/v1.3.3...v1.4.0) (2026-01-22)


### Features

* **dashboard:** add dynamic entity type and relationship options at graph_live.ex ([#29](https://github.com/georgeguimaraes/sorana/issues/29)) ([41ee981](https://github.com/georgeguimaraes/sorana/commit/41ee9811a26bd3699fe4e066a09edc92f0cc6ab8))


### Miscellaneous

* **deps-dev:** bump ex_doc from 0.39.3 to 0.40.0 ([#28](https://github.com/georgeguimaraes/sorana/issues/28)) ([8c1fb1f](https://github.com/georgeguimaraes/sorana/commit/8c1fb1f241c4440970fa72c7deda92ec4786c9fb))
* **deps:** bump igniter from 0.7.0 to 0.7.1 ([#31](https://github.com/georgeguimaraes/sorana/issues/31)) ([fcd441f](https://github.com/georgeguimaraes/sorana/commit/fcd441fdcc91f96043c1642098afdc44c264875f))


### Code Refactoring

* **ci:** use release-please for GitHub releases ([34f45c8](https://github.com/georgeguimaraes/sorana/commit/34f45c86721db54238fae141fec19dd9570c51bc))

## [1.3.3](https://github.com/georgeguimaraes/sorana/compare/v1.3.2...v1.3.3) (2026-01-20)


### Bug Fixes

* **dashboard:** flatten agentic results to fix KeyError on Ask page ([73e77a1](https://github.com/georgeguimaraes/sorana/commit/73e77a15f1356f46df283e1d1b5a72768e76de19)), closes [#25](https://github.com/georgeguimaraes/sorana/issues/25)

## [1.3.2](https://github.com/georgeguimaraes/sorana/compare/v1.3.1...v1.3.2) (2026-01-16)


### Miscellaneous

* **deps:** bump hnswlib from 0.1.6 to 0.1.7 ([#20](https://github.com/georgeguimaraes/sorana/issues/20)) ([6fb3b99](https://github.com/georgeguimaraes/sorana/commit/6fb3b991b94396005ba2802bcf832774192ccabb))
* **deps:** bump phoenix_live_view from 1.1.19 to 1.1.20 ([#21](https://github.com/georgeguimaraes/sorana/issues/21)) ([b1c298a](https://github.com/georgeguimaraes/sorana/commit/b1c298ad4117f5937e27d5ad3c60794554e23b24))
* **deps:** bump postgrex from 0.21.1 to 0.22.0 ([#19](https://github.com/georgeguimaraes/sorana/issues/19)) ([01410e1](https://github.com/georgeguimaraes/sorana/commit/01410e192180656c905263712fb7cb728c321605))
* **deps:** bump text_chunker from 0.5.2 to 0.6.0 ([#18](https://github.com/georgeguimaraes/sorana/issues/18)) ([c5ab08b](https://github.com/georgeguimaraes/sorana/commit/c5ab08b6130a010a96adeb9a2d38c766736a3ac0))


### Code Refactoring

* **ci:** remove redundant if from mark-release-tagged ([a8c7f4e](https://github.com/georgeguimaraes/sorana/commit/a8c7f4e34ebaab8a988816f8a77910e9ac992298))
* **ci:** use extract-version action ([2bd7ddc](https://github.com/georgeguimaraes/sorana/commit/2bd7ddcbafd9e24e842910ab6c1bf9f8a4183a4f))
* **ci:** use mark-release-tagged action ([3edb4b8](https://github.com/georgeguimaraes/sorana/commit/3edb4b883e4331e404a080b7d73e63c29832f9c1))
* **ci:** use shared workflows from georgeguimaraes/workflows ([9b8cab4](https://github.com/georgeguimaraes/sorana/commit/9b8cab4004f0d4104ce84e1913325e5a7f96a8cd))

## [1.3.1](https://github.com/georgeguimaraes/sorana/compare/v1.3.0...v1.3.1) (2026-01-16)


### Bug Fixes

* **ci:** checkout merge commit SHA when creating release tag ([f4d5a50](https://github.com/georgeguimaraes/sorana/commit/f4d5a50fe91f6b354c2a66e48003d8c842b5b341))
* **ci:** handle workflow_dispatch and yaml escaping issues ([149bfac](https://github.com/georgeguimaraes/sorana/commit/149bfacbe342918bcd145eb89ee3a89520f1c39a))
* support all forms of llm configuration on maintenance.ex ([#22](https://github.com/georgeguimaraes/sorana/issues/22)) ([6fec8f6](https://github.com/georgeguimaraes/sorana/commit/6fec8f6ed8b2477364202de6e052d7f010a8ec9d))


### Miscellaneous

* add fallback section for non-conventional commits in release-please ([5ec9e78](https://github.com/georgeguimaraes/sorana/commit/5ec9e7889ea090444ad0d18f00c2a386c6d3be77))

## [1.3.0](https://github.com/georgeguimaraes/sorana/compare/v1.2.0...v1.3.0) (2026-01-14)


### Features

* Add Build Graph button and mix sorana.rebuild_graph task ([d4f8aec](https://github.com/georgeguimaraes/sorana/commit/d4f8aec82f0188a38b9f49688ba8ed478d1e51cf))
* add ColBERT reranker using Stephen library ([7d078a0](https://github.com/georgeguimaraes/sorana/commit/7d078a01bd77389c908dd646bfc5a1985f785127))
* Add collection selector to Re-embed and improve displays ([950bb24](https://github.com/georgeguimaraes/sorana/commit/950bb249c2bfb99d8fffc6a2aec5c9375f0430af))
* Add collection selector to Rebuild Knowledge Graph ([abf7288](https://github.com/georgeguimaraes/sorana/commit/abf728891e03a1f702a1b9f56637c61e28c0a0ca))
* Add community detection maintenance task and UI ([d5e77e7](https://github.com/georgeguimaraes/sorana/commit/d5e77e74ecb71f3f7268b5be4a4d96beffb49f83))
* Add concurrency, resume and skip to rebuild_graph and reembed_chunks ([b023fa5](https://github.com/georgeguimaraes/sorana/commit/b023fa5eb08435143f2ccd6b0fbb0fc70fb46660))
* Add detailed stats to Collections page ([5f3d61e](https://github.com/georgeguimaraes/sorana/commit/5f3d61ef1fea4ca2cc001358daf2343edda34a26))
* Add fast Python leidenalg community detector ([78e00a2](https://github.com/georgeguimaraes/sorana/commit/78e00a27f7fb75375bc21d773ad92e9e3a34dc8e))
* Add gate and reason telemetry events to logger ([787becc](https://github.com/georgeguimaraes/sorana/commit/787becc0c7c2b6bb7031e9a1e8a25fecd8377b70))
* Add gate/2 and reason/2 for agentic RAG, split agent tests ([38dc6a1](https://github.com/georgeguimaraes/sorana/commit/38dc6a1a4e44c393c045be4ab8727a37843b862c))
* Add graph toggle to ingest and fix API key redaction ([c978452](https://github.com/georgeguimaraes/sorana/commit/c97845268b2f1df99e53d1554b00e68f3cd90033))
* Add hierarchical community detection with min_size filtering ([0648f4d](https://github.com/georgeguimaraes/sorana/commit/0648f4dcec9fa4caa76e66e9b81d6a27fd14452a))
* Add Leiden logging and CommunityDetector to Info page ([a7a04f3](https://github.com/georgeguimaraes/sorana/commit/a7a04f3b4c58bd683f015953b687866070bce193))
* Add mix sorana.graph.summarize_communities task ([ad42ed4](https://github.com/georgeguimaraes/sorana/commit/ad42ed4fd8e42cb5d65694af0ef557fb384eb417))
* Add orphaned graph data management to Maintenance page ([8d942fe](https://github.com/georgeguimaraes/sorana/commit/8d942fe26ec0b2a2994d3eacf2aff9f6183ebebe))
* Add pagination to graph explorer ([6797792](https://github.com/georgeguimaraes/sorana/commit/6797792bccce4a1d3c30ea2daff30b0de9f070a2))
* Add PDF parser behaviour for custom implementations ([08922bf](https://github.com/georgeguimaraes/sorana/commit/08922bfd9f242fa80464510eacf32205f4783c01))
* Add Rebuild Knowledge Graph to Maintenance page ([c9bc768](https://github.com/georgeguimaraes/sorana/commit/c9bc768efb5cc49c0d6ad9ab57d93a82662f22bf))
* Add theta option for faster Leiden convergence ([8e25236](https://github.com/georgeguimaraes/sorana/commit/8e2523661447e62cbee6c7d67c5837d9b00ae089))
* Display graph stats in dashboard when GraphRAG enabled ([ce1df09](https://github.com/georgeguimaraes/sorana/commit/ce1df095e4b7d853a3c783b971b29b9cfe418a94))
* Enhance Info page with more config details ([8d9a864](https://github.com/georgeguimaraes/sorana/commit/8d9a8649ae2c517d7b0fce18153086a62bf53853))
* Improve LLM select UI in Ask page ([acb71a8](https://github.com/georgeguimaraes/sorana/commit/acb71a8d5f69cce41db20116807d2b6f20ecd461))
* Pipeline components respect skip_retrieval flag ([ae65cb5](https://github.com/georgeguimaraes/sorana/commit/ae65cb5f45a96556bea8ec699140c072e4050420))
* Restructure Info page with expanded config display ([f6c1796](https://github.com/georgeguimaraes/sorana/commit/f6c1796602797e7520a7298f1731de0fc183335d))


### Bug Fixes

* Address Credo issues ([40387e2](https://github.com/georgeguimaraes/sorana/commit/40387e2f68e8d59e9881845a375652d517b027f9))
* Capture loading state from render_click return value ([3ecc10a](https://github.com/georgeguimaraes/sorana/commit/3ecc10aa2fe313c9b2d5f23f78d3de148b126591))
* **ci:** add include-v-in-tag to match existing tags ([4133649](https://github.com/georgeguimaraes/sorana/commit/4133649937dcdc2226d5d51e71d2c572dc2b2fa9))
* **ci:** add last-release-sha to bootstrap release-please state ([60ced9a](https://github.com/georgeguimaraes/sorana/commit/60ced9a47638d6d1134a74513bcef11b12a6395d))
* **ci:** bootstrap release-please to skip past PR [#6](https://github.com/georgeguimaraes/sorana/issues/6) ([de259ab](https://github.com/georgeguimaraes/sorana/commit/de259abb587a6b1eb625c6236206fbc1eec700c8))
* **ci:** match release PR title pattern to existing PRs ([0faf498](https://github.com/georgeguimaraes/sorana/commit/0faf4988273b6cc4d32baaff0c74bfbe7894f307))
* **ci:** update release PR label after creating release ([d121a13](https://github.com/georgeguimaraes/sorana/commit/d121a13252a3a95bdc4c7b5805899f8ec2617dd3))
* **ci:** use manifest mode for release-please ([710e659](https://github.com/georgeguimaraes/sorana/commit/710e6594f95241a283c97f91436cac97a26d8ed8))
* Convert indices to entity IDs in hierarchical community detection ([d387fd6](https://github.com/georgeguimaraes/sorana/commit/d387fd64fd7e316ee7c61c64f3a04c0b0b865118))
* credo warnings in ColBERT test ([39da83f](https://github.com/georgeguimaraes/sorana/commit/39da83f4078daf97833869e3e4882fe8e6014dac))
* Explicitly set enabled: false in test graph config ([662437f](https://github.com/georgeguimaraes/sorana/commit/662437ffc0ef6e4505565a28b7f2e7835e1390d3))
* Fix telemetry.span return value and add collection filter ([e2c9d22](https://github.com/georgeguimaraes/sorana/commit/e2c9d22b65d1d228700fc56123eccf017e1afd7d))
* Graph-Enhanced toggle styled as inline checkbox ([98fe03c](https://github.com/georgeguimaraes/sorana/commit/98fe03ce6bb807355edb87b640f6a291ad3187d1))
* Handle doc query param in documents page ([414046c](https://github.com/georgeguimaraes/sorana/commit/414046c232330bbe91d8f57801aafd2da1ee724d))
* Handle poppler_not_available error in PDF ingest test ([d33c409](https://github.com/georgeguimaraes/sorana/commit/d33c4097647656054416b9ddd5cd9f57508f6191))
* Improve community summary prompt to avoid generic intros ([b82471e](https://github.com/georgeguimaraes/sorana/commit/b82471e8d3dbdcd99adfab50cdd1f56ece3a5fb8))
* Join through Entity for relationship counts per collection ([87c5e18](https://github.com/georgeguimaraes/sorana/commit/87c5e182d79a7d89dd2e54bf34536cefada8bfc5))
* Lighten rel-type background and add section spacing ([ad3867c](https://github.com/georgeguimaraes/sorana/commit/ad3867ccd56e6cd8ca25b0824eab26d666d27909))
* Move Repository to info grid as card ([28d221e](https://github.com/georgeguimaraes/sorana/commit/28d221e238515add59ea419f7144caf1b5cb804a))
* Remove invalid collection_id queries from Relationship schema ([49ff631](https://github.com/georgeguimaraes/sorana/commit/49ff63181ce758aec1ed3f136c3b5eaee4011267))
* Remove long transactions from reembed to prevent DB timeout ([579b43d](https://github.com/georgeguimaraes/sorana/commit/579b43d8196592fc428ac717cae8da44a2993435))
* Reorganize Build Graph checkbox layout ([26a3bd4](https://github.com/georgeguimaraes/sorana/commit/26a3bd4838479a3690ede50a154bba033450cd11))
* Resolve DBConnection timeout errors in CI tests ([1e3dd63](https://github.com/georgeguimaraes/sorana/commit/1e3dd63750d0db8cf0b137f1ab2349d57c495b2d))
* Resolve NER serving race conditions and test isolation ([73510a1](https://github.com/georgeguimaraes/sorana/commit/73510a1c7187c3c704ac204a3aa96868f94a6aeb))
* Set minimum pool_size of 20 for CI environments ([035fdd6](https://github.com/georgeguimaraes/sorana/commit/035fdd631cd677a818ed21757b792f5eec9312cb))
* Show graph stats on collections page when data exists ([8a82559](https://github.com/georgeguimaraes/sorana/commit/8a82559a65c7ad477009094cc7058d7e4743f30f))
* Stabilize async tests with VACUUM on startup ([ab471da](https://github.com/georgeguimaraes/sorana/commit/ab471daad07c22c29e9561161c8b5c107bd3679d))
* Strengthen community summary prompt to prevent generic intros ([19d9c25](https://github.com/georgeguimaraes/sorana/commit/19d9c25ec181097d97c307992609ba9da5fe89d6))


### Miscellaneous

* add dependabot for daily dependency updates ([#11](https://github.com/georgeguimaraes/sorana/issues/11)) ([9ab9f70](https://github.com/georgeguimaraes/sorana/commit/9ab9f709de8a5c946a0cbf52caa8248f5bcc5974))
* **beads:** remove beads issue tracking system files ([6af715e](https://github.com/georgeguimaraes/sorana/commit/6af715e443c59c45cb4859afb780c51ba0bac7f8))
* **deps:** bump actions/cache from 3 to 5 ([#13](https://github.com/georgeguimaraes/sorana/issues/13)) ([2d649a9](https://github.com/georgeguimaraes/sorana/commit/2d649a984559854244dd0b72f219dfc336cc7c63))
* **deps:** bump actions/checkout from 4 to 6 ([#14](https://github.com/georgeguimaraes/sorana/issues/14)) ([315aefd](https://github.com/georgeguimaraes/sorana/commit/315aefd3c0fa34a6e1cc9d6af40ab1cc2fecf293))
* **deps:** bump amannn/action-semantic-pull-request from 5 to 6 ([#12](https://github.com/georgeguimaraes/sorana/issues/12)) ([7480a37](https://github.com/georgeguimaraes/sorana/commit/7480a37e77578c19afd5fbcbf259c9526d626c87))
* **deps:** use released stephen package from hex ([#16](https://github.com/georgeguimaraes/sorana/issues/16)) ([f8c1722](https://github.com/georgeguimaraes/sorana/commit/f8c1722cd3788a158479bab4757f7941da8651cd))
* Fix formatting and add Elixir 1.19/OTP 28 to test matrix ([ba4acb4](https://github.com/georgeguimaraes/sorana/commit/ba4acb49624a7a537ec6c95ca74ba0abe5b2b6fb))
* trigger release-please ([f75e54d](https://github.com/georgeguimaraes/sorana/commit/f75e54d2d8405dde7bc7bb38d0efb4d2eadf0e13))
* trigger release-please ([ba32722](https://github.com/georgeguimaraes/sorana/commit/ba3272202315a5475f9e96528b7deb4dfce9acc5))
* trigger release-please ([b03b4a7](https://github.com/georgeguimaraes/sorana/commit/b03b4a71e1869b235d3b63edd0a05dee3a333e0c))
* Update leidenfold to 0.3.2 ([fb364e2](https://github.com/georgeguimaraes/sorana/commit/fb364e271b36a54a11e42c83a4d85983443c5855))
* Use proper Elixir/OTP version matrix in CI ([56e5db6](https://github.com/georgeguimaraes/sorana/commit/56e5db61045ecacdfe11d46e07cbb17e57f24c5b))


### Documentation

* Add Maintenance Tasks section to GraphRAG guide ([61dae86](https://github.com/georgeguimaraes/sorana/commit/61dae860e9c32bd82c51399c1ae5f6a4054bf4d2))
* Add PDF parser configuration documentation ([c958e2f](https://github.com/georgeguimaraes/sorana/commit/c958e2f42d66a8ed38ed043c3057161911717a72))
* Update 'How it works' section with current architecture ([0f1d00a](https://github.com/georgeguimaraes/sorana/commit/0f1d00a4f07e20c1b5edd7d351cfd5970d27f2f0))
* Update sorana version to ~&gt; 1.0 ([6ea1fa7](https://github.com/georgeguimaraes/sorana/commit/6ea1fa746cf621e2881e28364b9a46f3ebe01d0b))


### Code Refactoring

* Fix credo issues in agent.ex ([b1f3ee2](https://github.com/georgeguimaraes/sorana/commit/b1f3ee2b68e33ff53ed718b63d430fb29674bbd5))
* Remove typespecs from codebase ([2c34f0d](https://github.com/georgeguimaraes/sorana/commit/2c34f0d514b09ea962d9b4fb6a897aab49ce04d1))
* Replace ex_leiden/leidenalg with leidenfold for community detection ([addef8d](https://github.com/georgeguimaraes/sorana/commit/addef8d1c90b23925600f428f45f4fe62068e55e))
* Use leidenfold native hierarchical detection ([70c4ed8](https://github.com/georgeguimaraes/sorana/commit/70c4ed8265b0df6923981c755e960653cfee1819))
* Use TaskSupervisor for dashboard async operations ([14de97f](https://github.com/georgeguimaraes/sorana/commit/14de97f8d69837db87e00a0848978daabfd9028d))


### Performance Improvements

* Optimize list_entities query with subqueries ([f343e51](https://github.com/georgeguimaraes/sorana/commit/f343e51ff3f6d6940158a77099fea154118d4bf4))

## [1.2.0](https://github.com/georgeguimaraes/sorana/compare/v1.1.0...v1.2.0) (2026-01-03)


### Features

* Add E5 embedding model prefix support ([8a0d8a5](https://github.com/georgeguimaraes/sorana/commit/8a0d8a52d6bada8d1472d9c258dfa1df2b93068f))
* Add GraphRAG (Graph-enhanced Retrieval Augmented Generation) ([#7](https://github.com/georgeguimaraes/sorana/issues/7)) ([4faca71](https://github.com/georgeguimaraes/sorana/commit/4faca71f390439b6774b7e84638bf4112f881dbe))
* Add swappable GraphStore backend ([#9](https://github.com/georgeguimaraes/sorana/issues/9)) ([42e7074](https://github.com/georgeguimaraes/sorana/commit/42e7074028c4c9e5269f68a6e49782e36a6adb87))
* Add swappable GraphStore issues from GitHub [#8](https://github.com/georgeguimaraes/sorana/issues/8) ([7adb131](https://github.com/georgeguimaraes/sorana/commit/7adb13193193ed022050ba8cadcf24a0f2ce413a))
* Add telemetry to GraphStore and VectorStore ([61f4f3d](https://github.com/georgeguimaraes/sorana/commit/61f4f3d5d7946df8501d5e4caf1e3dcceaea6ae9))
* Make Nx backend configurable (EXLA, EMLX, Torchx) ([#5](https://github.com/georgeguimaraes/sorana/issues/5)) ([86b8ef9](https://github.com/georgeguimaraes/sorana/commit/86b8ef9e251b8366fb62af0dba0165762ba07478))

## [1.1.0](https://github.com/georgeguimaraes/sorana/compare/v1.0.0...v1.1.0) (2026-01-01)


### Features

* Add pluggable Chunker behaviour for custom chunking strategies ([4452374](https://github.com/georgeguimaraes/sorana/commit/44523744ac2c177d4c6966e19e3e28971bf947af))
* Add release workflow with GitHub-generated notes ([7bf5568](https://github.com/georgeguimaraes/sorana/commit/7bf55681adb53773af4bd7d6843e236bfdfe5cfa))
* Add single-query hybrid search for pgvector backend ([97e86b2](https://github.com/georgeguimaraes/sorana/commit/97e86b2ba7c9e321021b6dc8b87a136892a67adf))


### Bug Fixes

* Add validations to Evaluation Run and TestCase changesets ([d1c0963](https://github.com/georgeguimaraes/sorana/commit/d1c0963f48767bb36baac0596ea9c3e8fa7daaa7))
* Consistent error handling across API ([7d246ea](https://github.com/georgeguimaraes/sorana/commit/7d246ea31882123734a7b89192d581aa011f670f))
* Extract global config tests to separate async: false module ([90293d4](https://github.com/georgeguimaraes/sorana/commit/90293d49bf8bace7778113c79b665fab760fe824))
* Make EmbedderTest async: false to prevent config races ([ccb47d7](https://github.com/georgeguimaraes/sorana/commit/ccb47d7f307ea7c4b0673af3abc3a603d080139f))
* Make evaluation run async to avoid blocking LiveView ([e2f0321](https://github.com/georgeguimaraes/sorana/commit/e2f0321fe2403c13acbf0e2484bc53aa230cb6b9))
* Make evaluation run async with supervised tasks ([19553ec](https://github.com/georgeguimaraes/sorana/commit/19553ecdd575f39d6a8238232b0d3a759440080a))
* Move DB queries from mount() to handle_params() in LiveViews ([c48d3bd](https://github.com/georgeguimaraes/sorana/commit/c48d3bd20cbeb056ece47c4dfd9d237fef4ee805))
* Resolve credo warnings for CI ([ecaf1bd](https://github.com/georgeguimaraes/sorana/commit/ecaf1bd6c9aefecc43412336cc0c01aa60ab23ef))
* Use plainto_tsquery for safe fulltext search input ([3379ff0](https://github.com/georgeguimaraes/sorana/commit/3379ff05d3d9c960590805e9b3813e2698dbba4d))
* Validate UUID format in Chunk changeset ([6481101](https://github.com/georgeguimaraes/sorana/commit/648110109cabaa57e2cb4e3e4525349ed32f959b))

## 1.0.0 (2025-12-30)


### Features

* Add Agent pipeline with context struct ([6e0f891](https://github.com/georgeguimaraes/sorana/commit/6e0f8912ca6a9bc3e29043d44b69a162265c9a2e))
* Add Agent.rewrite/2 and consistent :llm option across Agent functions ([efb2395](https://github.com/georgeguimaraes/sorana/commit/efb239500040c5387b77b38203e70d2f3bf5f606))
* Add Agentic Search tab to Dashboard ([88feac7](https://github.com/georgeguimaraes/sorana/commit/88feac78902dd6bfba9fea95312a3b28a268249e))
* Add Sorana brand text to stats ribbon ([1057866](https://github.com/georgeguimaraes/sorana/commit/1057866fa3907c0adb2c7a545857d57129d76acd))
* Add Sorana.Telemetry.Logger for easy telemetry logging ([6f3954e](https://github.com/georgeguimaraes/sorana/commit/6f3954e6688d3157d822c7465616a976665c55f0))
* Add behaviours for all Agent pipeline components ([e2355ac](https://github.com/georgeguimaraes/sorana/commit/e2355acd148b6de44d6e4dc2c291af6c21c1817d))
* Add collection filter for evaluation test case generation ([a416cb4](https://github.com/georgeguimaraes/sorana/commit/a416cb460b3617e9cd0f16957cac81f68ae27006))
* Add collection filter to Documents tab ([b441b8f](https://github.com/georgeguimaraes/sorana/commit/b441b8fb75470304f9e4e2b1490e95d3343ac909))
* Add collection option to Agent.search for explicit collection selection ([40b8a65](https://github.com/georgeguimaraes/sorana/commit/40b8a6556b7e883e882e925305f961eb4dbf12de))
* Add collection routing to Agent pipeline ([c46b699](https://github.com/georgeguimaraes/sorana/commit/c46b69939d9420d32d0127f09f582614717dd7dc))
* Add collections for document segmentation and file upload UI ([eccbb21](https://github.com/georgeguimaraes/sorana/commit/eccbb21bd6062467e27cd454af9070d4f9eada37))
* Add Collections tab to dashboard with CRUD operations ([7211760](https://github.com/georgeguimaraes/sorana/commit/721176005f31b6e133347731270f55efdfc08864))
* Add configurable embedding providers ([4f3aa93](https://github.com/georgeguimaraes/sorana/commit/4f3aa934178b28b113a382cc412d6f87ceeb6a49))
* Add configurable prompts to Agent and ask/2 ([42ea3b4](https://github.com/georgeguimaraes/sorana/commit/42ea3b4836373f6edfd8231ef91f9f3610f231fc))
* Add Document/Chunk schemas and mix sorana.install task ([bc48045](https://github.com/georgeguimaraes/sorana/commit/bc48045209ac13998674de8def9103919cc10f92))
* Add end-to-end answer evaluation with faithfulness scoring ([d14048a](https://github.com/georgeguimaraes/sorana/commit/d14048a9f1e1b45aee2db7a424d38d15b3e597c2))
* Add end-to-end tests for LLM integration ([d909b1c](https://github.com/georgeguimaraes/sorana/commit/d909b1c0cd5bed058c214c6e4f08a95857a398ed))
* Add foundation - Chunker and Embeddings with TDD ([6a3fb78](https://github.com/georgeguimaraes/sorana/commit/6a3fb783ad4b62238d512b93656a818bbf3345d2))
* Add fulltext search to VectorStore and wire all modes ([4ebc227](https://github.com/georgeguimaraes/sorana/commit/4ebc227ee188ec9c86a333c09be7923d594c75b5))
* Add generate test cases button to dashboard ([1d935f1](https://github.com/georgeguimaraes/sorana/commit/1d935f159e3c4e741eb45e4c9d01f6abafc1c043))
* Add hybrid search with vector + full-text fusion ([1801ea5](https://github.com/georgeguimaraes/sorana/commit/1801ea5b79938b57a660bc850ac2c794df53c99e))
* Add icons to action buttons in Documents and Collections pages ([14fa9e3](https://github.com/georgeguimaraes/sorana/commit/14fa9e3e7722fe5a8386b9d94b53a806ad5493f2))
* Add Igniter-powered installer for automatic setup ([7ffb03e](https://github.com/georgeguimaraes/sorana/commit/7ffb03e86389c2cbca8266a5fbd573dda8929ef6))
* Add in-memory vector store backend with HNSWLib ([f6ca251](https://github.com/georgeguimaraes/sorana/commit/f6ca251ff60d569bb768563ed9fd5a0e493f824f))
* Add Info tab to dashboard showing all configuration ([94ce4dc](https://github.com/georgeguimaraes/sorana/commit/94ce4dc91460b9737154207422e2d8e55db44e29))
* Add LiveView dashboard with purple theme ([c2967f1](https://github.com/georgeguimaraes/sorana/commit/c2967f14ad621c420e6bcea511cf12c7bcd7c810))
* Add LLM protocol for flexible LLM integration ([d0f7389](https://github.com/georgeguimaraes/sorana/commit/d0f7389d6aa91ec86dc57e285305e83867a9b573))
* Add macro-based router for embeddable dashboard ([1d1a5e0](https://github.com/georgeguimaraes/sorana/commit/1d1a5e0f37f63c36ee4ac067b0bb4d1990ccb9d6))
* Add multi-select collection filter to Ask and Search tabs ([aa64402](https://github.com/georgeguimaraes/sorana/commit/aa6440269c07da6e43b0ff788466b023a677dc3e))
* Add PDF and document file parsing ([dc59c30](https://github.com/georgeguimaraes/sorana/commit/dc59c30d48f1c8f256920ae1b049da2fb0c8916b))
* Add per-call :vector_store option for backend override ([2753525](https://github.com/georgeguimaraes/sorana/commit/27535250b1a22e3a95d863d136eb2f2ac41d446d))
* Add pluggable Selector behaviour for Agent.select ([2ea0a81](https://github.com/georgeguimaraes/sorana/commit/2ea0a81e9f1d8ee063856e0a1579424524fceb56))
* Add query expansion step to Agent pipeline ([993d5c2](https://github.com/georgeguimaraes/sorana/commit/993d5c2c655722e251135b3209894573ed5ab72a))
* Add query rewriting with LLM support ([5cc2ddb](https://github.com/georgeguimaraes/sorana/commit/5cc2ddb32d6f2b2b49e6da5a6e9d0f4b52072d05))
* Add question decomposition to Agent pipeline ([eef463b](https://github.com/georgeguimaraes/sorana/commit/eef463b03843f488c80faafe3a8ec9b36ca5c698))
* Add RAG pipeline with Sorana.ask/2 ([8853588](https://github.com/georgeguimaraes/sorana/commit/885358869bbad1dfa89ed6ee2c3f86bba5e9c0d1))
* Add re-ranking step to Agent pipeline ([4330ccf](https://github.com/georgeguimaraes/sorana/commit/4330ccf413956b4ab5c7f795d280f5f0f1bd52f4))
* Add reranker config to dashboard Info tab and EvaluationRun ([3b857f4](https://github.com/georgeguimaraes/sorana/commit/3b857f4b1a41a2ffb2369148f37afc3664f6b664))
* Add retrieval evaluation system ([342da85](https://github.com/georgeguimaraes/sorana/commit/342da8594194e050a2f64e4f830a0daa4f399346))
* Add rewriter helpers (expand, keywords, decompose) ([fc41ef8](https://github.com/georgeguimaraes/sorana/commit/fc41ef8d4556051d4823757114fccc72d854f5d7))
* Add self-correcting answers and consistent :llm option across Agent functions ([9d21572](https://github.com/georgeguimaraes/sorana/commit/9d2157246a9c653eba2407d4e88e7795cbd0038f))
* Add self-correcting search to Agent pipeline ([dd8d458](https://github.com/georgeguimaraes/sorana/commit/dd8d4581bdc37517ac50a0e890b91251da88d51a))
* Add Simple/Agentic mode toggle to Ask tab ([9f73a18](https://github.com/georgeguimaraes/sorana/commit/9f73a18eb82d2af080ed9da0a2c3d21a72b35357))
* Add stats, pagination, and document detail view to dashboard ([6d72c37](https://github.com/georgeguimaraes/sorana/commit/6d72c378c2d593566c6b00af1d2f7c542282aac6))
* Add telemetry events for observability ([4ea68af](https://github.com/georgeguimaraes/sorana/commit/4ea68afe72af0db57342432abe7160bae8f5e2cb))
* Add telemetry for LLM calls ([2bb449b](https://github.com/georgeguimaraes/sorana/commit/2bb449b87f47c90a4a1297d8125d21093ce5b5a3))
* Add tuple LLM config and improve ask return value ([28ffb00](https://github.com/georgeguimaraes/sorana/commit/28ffb005fe34ca6b95ff490b7ee0b6db4a0068ce))
* Add Z.ai embeddings and rename Embedding to Embedder ([9453241](https://github.com/georgeguimaraes/sorana/commit/9453241beed7ea9225aadf27777123ee3a2ebac7))
* Complete minimal RAG loop with public API ([bc11d49](https://github.com/georgeguimaraes/sorana/commit/bc11d490122f52c76892b30fd8ab7fe8bab7cfe8))
* Enhance dashboard with search modes and format options ([8211881](https://github.com/georgeguimaraes/sorana/commit/82118816d5163b19ec90f0c933d07c80f827edef))
* Improve query decomposition prompt ([5314506](https://github.com/georgeguimaraes/sorana/commit/5314506b0f684df91e800d6c0174d90e1f580e79))
* Improve query expansion prompt ([30c72c2](https://github.com/georgeguimaraes/sorana/commit/30c72c2c7affe9d708fd9149824239a3be59fc57))
* Include collection descriptions in select/2 prompt ([d7e9aa6](https://github.com/georgeguimaraes/sorana/commit/d7e9aa6878c932894945eb36e97446364cc4c62a))
* Make PDF support optional ([79bdcac](https://github.com/georgeguimaraes/sorana/commit/79bdcacdc6b05135707cdc7160807d7f25716cd0))
* Replace custom chunker with text_chunker library ([33657c5](https://github.com/georgeguimaraes/sorana/commit/33657c56547ff609739f476c3d12465bfa90ca36))
* Save Sorana config in evaluation runs ([3731f8f](https://github.com/georgeguimaraes/sorana/commit/3731f8f9951860c91ab136574b5e4551df406bc2))
* Support collection descriptions in ingest/2 ([f92d9d0](https://github.com/georgeguimaraes/sorana/commit/f92d9d0a4a98ec90f6d1895b0038a44cb6bbf334))
* Support custom module embedding implementations ([6af20a7](https://github.com/georgeguimaraes/sorana/commit/6af20a71fd661536028163e07893cce81864006c))
* Support provider_options passthrough for LLM calls ([51b05c9](https://github.com/georgeguimaraes/sorana/commit/51b05c9c8ec496ec79b08a450acc495411b5bc28))
* Use req_llm fork with Z.ai thinking parameter support ([f0b721e](https://github.com/georgeguimaraes/sorana/commit/f0b721eccceb93071d0d7c9810502b859a6fdd4a))


### Bug Fixes

* Add collections table to migration template ([6ae13e3](https://github.com/georgeguimaraes/sorana/commit/6ae13e3db3b330b84728e3cad3f44e20acd4db8d))
* Address credo warnings and code style issues ([89326c2](https://github.com/georgeguimaraes/sorana/commit/89326c26cdaee8e66742b0fe79d83e57556e4577))
* Align action buttons in documents table ([0a221e8](https://github.com/georgeguimaraes/sorana/commit/0a221e830233f59b9a7749fd72d5a242c5841288))
* Align Search tab collection CSS with Ask tab ([b5b4d95](https://github.com/georgeguimaraes/sorana/commit/b5b4d95089f8c39d25d35bf0a11e78ae24e63fee))
* Center icons in Actions column ([b77727e](https://github.com/georgeguimaraes/sorana/commit/b77727eb06664e5d28d0d4fe3e1ee996a7b50a5e))
* Correct name in LICENSE to match README ([f7dc44f](https://github.com/georgeguimaraes/sorana/commit/f7dc44f025065dcefa41a96b15e206f4ea0328eb))
* Filter out whitespace-only chunks during text splitting ([b9571cc](https://github.com/georgeguimaraes/sorana/commit/b9571cc2594676e8eca134aea2ea18a40590b257))
* Fix ask_live template and telemetry logger ([ead2638](https://github.com/georgeguimaraes/sorana/commit/ead26382cefe854af1972edd266092e724c23f23))
* Fix flaky tests and update README license format ([40c77d0](https://github.com/georgeguimaraes/sorana/commit/40c77d01e2782a704997e025627de7ef913f7e85))
* Improve document detail view styling consistency ([c94f42a](https://github.com/georgeguimaraes/sorana/commit/c94f42ab0c350bd312de4c82750b162aa4a5f196))
* Improve documents table styling ([68557b7](https://github.com/georgeguimaraes/sorana/commit/68557b7bc39ccd54845a89cce61b99b073e4176c))
* Include model metadata in telemetry stop events ([dff225c](https://github.com/georgeguimaraes/sorana/commit/dff225c9f53813894dd3fd5210a4ff5036d7f856))
* Install cmake in CI for hnswlib compilation ([ff9de44](https://github.com/georgeguimaraes/sorana/commit/ff9de44c071cc5f4d4079c10c0a2def1c812471d))
* Lower default chunk_size to 450 tokens for model safety margin ([a2ccd8c](https://github.com/georgeguimaraes/sorana/commit/a2ccd8cb79251a0ab1f384580a92ddc6da7e8c7b))
* Make Sorana brand text bigger and vertically centered ([7248784](https://github.com/georgeguimaraes/sorana/commit/72487845889d11a6529a8e32ab10bb1c1f9554ac))
* Make file upload dropzone clickable ([63801fc](https://github.com/georgeguimaraes/sorana/commit/63801fc662f987de254caf5ddb30a63df6b8fe8d))
* Move collection checkbox CSS to main style block ([3ba2a5d](https://github.com/georgeguimaraes/sorana/commit/3ba2a5ddd187fc7e86638150e99f1fae07e4121b))
* Prefix unused variables with underscore in tests ([5311878](https://github.com/georgeguimaraes/sorana/commit/531187834baa49cebd4804438292a9d159cec4b7))
* Redact sensitive keys (api_key, token, etc.) in Info page ([ba2070a](https://github.com/georgeguimaraes/sorana/commit/ba2070a76cc46a187940f7196e98545f3ae96e64))
* Remove sorana-actions class to fix button alignment ([0092605](https://github.com/georgeguimaraes/sorana/commit/00926050319b8aeed812314e645b0315fb2afa22))
* Remove borders from Documents page icon buttons ([d8486cf](https://github.com/georgeguimaraes/sorana/commit/d8486cfa7b3b598f6974f527975259185bdf3200))
* Remove elixir_make override and update hnswlib ([deba0cf](https://github.com/georgeguimaraes/sorana/commit/deba0cf6e5fc5aa987df8d656614eb0a1e7e1c25))
* Set MIX_ENV=test for CI database setup ([ac1d5f0](https://github.com/georgeguimaraes/sorana/commit/ac1d5f0e4317205e70e4748d76aa8c2216ecc53b))
* Specify postgres user in CI health check ([dedfb77](https://github.com/georgeguimaraes/sorana/commit/dedfb7724e9c343f7814dbf6a9c98b1dc8bf8495))
* Start host app in mix sorana.reembed task ([baf5678](https://github.com/georgeguimaraes/sorana/commit/baf56789d0b0fafaac38a3c9a66334d7395ea5ee))
* Trim leading/trailing whitespace from LLM answers ([74aa858](https://github.com/georgeguimaraes/sorana/commit/74aa8583d823241a63c7798c19fea2d3ccb1d5ba))
* Update sorana.install to use correct Embedding.Local module ([d22c28a](https://github.com/georgeguimaraes/sorana/commit/d22c28a674b8b0710aabf3ba8f79044373be99c5))
* Use apply/3 for optional dependencies to avoid compile warnings ([fe9ab70](https://github.com/georgeguimaraes/sorana/commit/fe9ab70c5cb54b0546c37b0b561f2fdf1872145b))
* Use async: false for telemetry tests ([09c4ffa](https://github.com/georgeguimaraes/sorana/commit/09c4ffac5563d41f76e198fbf5579abfc9d585b7))
* Use text-align for Actions column centering ([8dd7340](https://github.com/georgeguimaraes/sorana/commit/8dd7340cbf5a8958681034816d74a3f5e98e77c6))
* Use trash icon for delete button in test cases list ([e81ea5b](https://github.com/georgeguimaraes/sorana/commit/e81ea5b0b9d3172a1588db7ea17941b687b46958))

## [0.1.0] - 2025-01-01

### Added

- Core RAG API: `ingest/2`, `search/2`, `ask/2`, `delete/2`
- Agentic RAG pipeline with `Sorana.Agent`:
  - `rewrite/2` - Clean up conversational input
  - `select/2` - LLM-based collection selection
  - `expand/2` - Query expansion with synonyms
  - `decompose/2` - Multi-part question decomposition
  - `search/2` - Vector search across collections
  - `rerank/2` - LLM-based relevance scoring
  - `answer/2` - Answer generation with self-correction
- Pluggable components via behaviours for all pipeline steps
- Embedding providers:
  - Local Bumblebee (default, no API keys)
  - OpenAI
  - Custom via `Sorana.Embedder` behaviour
- Vector store backends:
  - pgvector (default)
  - In-memory HNSWLib
  - Custom via `Sorana.VectorStore` behaviour
- Search modes: semantic, fulltext, hybrid (RRF fusion)
- File ingestion: text, markdown, PDF
- Collections for document segmentation
- Evaluation system with MRR, Recall, Precision, Hit Rate metrics
- LiveView dashboard for document management and search
- Telemetry events for observability
- Igniter installer for streamlined setup
