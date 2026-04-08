# Telemetry and Observability

Sorana emits telemetry events for all operations, giving you visibility into performance, errors, and usage patterns. This guide covers setup options from quick debugging to full production monitoring.

## Quick Start

For immediate visibility, attach the built-in logger in your application startup:

```elixir
# lib/my_app/application.ex
def start(_type, _args) do
  # Attach telemetry logger before starting supervision tree
  Sorana.Telemetry.Logger.attach()

  children = [
    MyApp.Repo,
    Sorana.TaskSupervisor,
    Sorana.Embedder.Local
  ]

  Supervisor.start_link(children, strategy: :one_for_one)
end
```

This logs all Sorana operations with timing:

```
[info] [Sorana] search completed in 42ms (15 results)
[info] [Sorana] llm.complete completed in 1.23s [openai:gpt-4o-mini] ok (156 chars) prompt=892chars
[info] [Sorana] pipeline.gate completed in 180ms (skip_retrieval: false)
[info] [Sorana] pipeline.rewrite completed in 235ms
[info] [Sorana] pipeline.expand completed in 2.15s ("machine learning ML models...")
[info] [Sorana] pipeline.search completed in 156ms (25 chunks)
[info] [Sorana] pipeline.reason completed in 1.2s (1 iteration)
[info] [Sorana] pipeline.rerank completed in 312ms (10/25 kept)
[info] [Sorana] pipeline.answer completed in 3.25s
[info] [Sorana] pipeline.ground completed in 85ms (score: 0.95, 1 hallucinated span)
[info] [Sorana] ask completed in 6.12s
```

With `graph: true` enabled, you'll also see:

```
[info] [Sorana] graph.ner completed in 45ms (3 entities)
[info] [Sorana] graph.relationship_extraction completed in 1.2s (2 relationships)
[info] [Sorana] graph.build completed in 1.5s (5 entities, 3 relationships)
[info] [Sorana] graph.search completed in 28ms (8 graph results, 10 combined)
```

### Logger Options

```elixir
Sorana.Telemetry.Logger.attach(
  level: :debug,           # Log level (default: :info)
  handler_id: "my-logger"  # Custom handler ID
)

# To stop logging
Sorana.Telemetry.Logger.detach()
```

## Event Reference

All events use `:telemetry.span/3`, which emits `:start`, `:stop`, and `:exception` variants automatically.

### Core Events

| Event | Measurements | Metadata |
|-------|--------------|----------|
| `[:sorana, :ingest, :*]` | `system_time`, `duration` | `text`, `repo`, `collection`, `document`, `chunk_count` |
| `[:sorana, :search, :*]` | `system_time`, `duration` | `query`, `repo`, `mode`, `limit`, `results`, `result_count` |
| `[:sorana, :ask, :*]` | `system_time`, `duration` | `question`, `repo`, `answer`, `context_count` |
| `[:sorana, :embed, :*]` | `system_time`, `duration` | `text`, `dimensions` |
| `[:sorana, :llm, :complete, :*]` | `system_time`, `duration` | `model`, `prompt_length`, `success`, `response_length`, `error` |

### Pipeline Events

Each step in `Sorana.Pipeline` emits its own span under `[:sorana, :pipeline, ...]`. The events were previously emitted under `[:sorana, :agent, ...]`; that prefix was renamed to `:pipeline` along with the module rename and is no longer emitted. Update any existing handlers.

| Event | Metadata |
|-------|----------|
| `[:sorana, :pipeline, :gate, :*]` | `question`, `skip_retrieval` |
| `[:sorana, :pipeline, :rewrite, :*]` | `question`, `rewritten_query` |
| `[:sorana, :pipeline, :select, :*]` | `selected` (collections) |
| `[:sorana, :pipeline, :expand, :*]` | `question`, `expanded_query` |
| `[:sorana, :pipeline, :decompose, :*]` | `question`, `sub_question_count` |
| `[:sorana, :pipeline, :search, :*]` | `question`, `total_chunks` |
| `[:sorana, :pipeline, :reason, :*]` | `question`, `iterations` |
| `[:sorana, :pipeline, :rerank, :*]` | `question`, `chunks_before`, `chunks_after` |
| `[:sorana, :pipeline, :answer, :*]` | `question`, `context_chunk_count` |
| `[:sorana, :pipeline, :ground, :*]` | `score`, `hallucinated_span_count`, `faithful_span_count` |

### Loop Events

`Sorana.Loop` emits a span around the whole agent loop run plus a
discrete event after each tool call:

| Event | Metadata |
|-------|----------|
| `[:sorana, :loop, :*]` | `question`, `max_iterations`, `tool_count`, `iterations`, `terminated_by` |
| `[:sorana, :loop, :tool_call]` | `tool`, `args`, `iteration`, `summary`, `returned_chunk_ids` |
| `[:sorana, :loop, :ground, :*]` | `chunk_count`, `answer_present` |

The `:terminated_by` value on the run-level span tells you how the loop
ended: `:answered`, `:gave_up`, `:max_iterations`, or `:error`.

`[:sorana, :loop, :tool_call]` fires once per tool call as it lands in
the tool history. The metadata mirrors a single `tool_history` entry
exactly, so you can use it to render a live trace as the agent works.
This is what powers the "Agent thinking" panel in the dashboard's Loop
sub-tab. The measurements include `count: 1` and `history_size: n` so
you can build counters or histograms over the per-call distribution.

```elixir
:telemetry.attach(
  "loop-trace",
  [:sorana, :loop, :tool_call],
  fn _event, _measurements, metadata, _config ->
    IO.puts("[#{metadata.iteration}] #{metadata.tool}: #{inspect(metadata.args)}")
  end,
  nil
)
```

The search tool's underlying retrieval also emits `[:sorana, :search, :*]`
events from inside `Sorana.search/2`, so you can correlate per-tool-call
events with per-search timing if you need finer detail.

### VectorStore Events

Storage layer events for vector operations:

| Event | Metadata |
|-------|----------|
| `[:sorana, :vector_store, :store, :*]` | `collection`, `id`, `backend` |
| `[:sorana, :vector_store, :search, :*]` | `collection`, `limit`, `backend`, `result_count` |
| `[:sorana, :vector_store, :search_text, :*]` | `collection`, `query`, `limit`, `backend`, `result_count` |
| `[:sorana, :vector_store, :delete, :*]` | `collection`, `id`, `backend` |
| `[:sorana, :vector_store, :clear, :*]` | `collection`, `backend` |

### GraphRAG Events

When using `graph: true`, these events track knowledge graph operations:

| Event | Metadata |
|-------|----------|
| `[:sorana, :graph, :build, :*]` | `chunk_count`, `collection`, `entity_count`, `relationship_count` |
| `[:sorana, :graph, :search, :*]` | `query`, `entity_count`, `graph_result_count`, `combined_count` |
| `[:sorana, :graph, :ner, :*]` | `text`, `entity_count` |
| `[:sorana, :graph, :relationship_extraction, :*]` | `text`, `relationship_count` |
| `[:sorana, :graph, :community_detection, :*]` | `entity_count`, `community_count` |
| `[:sorana, :graph, :community_summary, :*]` | `entity_count`, `summary_length` |

### GraphStore Events

Storage layer events for graph operations:

| Event | Metadata |
|-------|----------|
| `[:sorana, :graph_store, :persist_entities, :*]` | `collection_id`, `entity_count`, `backend` |
| `[:sorana, :graph_store, :persist_relationships, :*]` | `relationship_count`, `backend` |
| `[:sorana, :graph_store, :persist_mentions, :*]` | `mention_count`, `backend` |
| `[:sorana, :graph_store, :search, :*]` | `entity_count`, `backend`, `result_count` |
| `[:sorana, :graph_store, :delete_by_chunks, :*]` | `chunk_count`, `backend` |
| `[:sorana, :graph_store, :delete_by_collection, :*]` | `collection_id`, `backend` |

### Exception Events

All `:exception` events include:
- `kind` - The exception type (`:error`, `:exit`, `:throw`)
- `reason` - The exception or error term
- `stacktrace` - Full stacktrace

## Custom Handlers

For more control, attach your own handlers:

```elixir
defmodule MyApp.SoranaMetrics do
  require Logger

  def setup do
    events = [
      [:sorana, :ingest, :stop],
      [:sorana, :search, :stop],
      [:sorana, :ask, :stop],
      [:sorana, :embed, :stop],
      [:sorana, :llm, :complete, :stop],
      # Pipeline
      [:sorana, :pipeline, :gate, :stop],
      [:sorana, :pipeline, :rerank, :stop],
      [:sorana, :pipeline, :reason, :stop],
      [:sorana, :pipeline, :answer, :stop],
      [:sorana, :pipeline, :ground, :stop],
      # Loop
      [:sorana, :loop, :stop],
      [:sorana, :loop, :tool_call],
      [:sorana, :loop, :ground, :stop],
      # VectorStore
      [:sorana, :vector_store, :store, :stop],
      [:sorana, :vector_store, :search, :stop],
      # GraphRAG
      [:sorana, :graph, :build, :stop],
      [:sorana, :graph, :search, :stop],
      # GraphStore
      [:sorana, :graph_store, :persist_entities, :stop],
      [:sorana, :graph_store, :search, :stop]
    ]

    :telemetry.attach_many("my-sorana-metrics", events, &handle_event/4, nil)
  end

  def handle_event([:sorana, :search, :stop], measurements, metadata, _config) do
    duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)

    Logger.info("Search: #{metadata.result_count} results in #{duration_ms}ms",
      query: metadata.query,
      mode: metadata.mode
    )

    # Send to your metrics system
    :telemetry.execute([:my_app, :sorana, :search], %{
      duration_ms: duration_ms,
      result_count: metadata.result_count
    })
  end

  def handle_event([:sorana, :llm, :complete, :stop], measurements, metadata, _config) do
    duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)

    if metadata.success do
      Logger.debug("LLM call to #{metadata.model}: #{duration_ms}ms")
    else
      Logger.warning("LLM call failed: #{metadata.error}")
    end
  end

  # ... handle other events
end
```

Call `MyApp.SoranaMetrics.setup()` in your application startup.

## Phoenix LiveDashboard Integration

Add Sorana metrics to your LiveDashboard:

```elixir
# lib/my_app/telemetry.ex
defmodule MyApp.Telemetry do
  import Telemetry.Metrics

  def metrics do
    [
      # Sorana core operations
      summary("sorana.ingest.stop.duration",
        unit: {:native, :millisecond},
        tags: [:collection]
      ),
      summary("sorana.search.stop.duration",
        unit: {:native, :millisecond},
        tags: [:mode]
      ),
      counter("sorana.search.stop.result_count"),
      summary("sorana.ask.stop.duration",
        unit: {:native, :millisecond}
      ),

      # Embedding performance
      summary("sorana.embed.stop.duration",
        unit: {:native, :millisecond}
      ),

      # LLM calls (often the slowest part)
      summary("sorana.llm.complete.stop.duration",
        unit: {:native, :millisecond},
        tags: [:model]
      ),
      counter("sorana.llm.complete.stop.prompt_length"),

      # Pipeline steps
      summary("sorana.pipeline.rerank.stop.duration",
        unit: {:native, :millisecond}
      ),
      last_value("sorana.pipeline.rerank.stop.kept"),
      summary("sorana.pipeline.answer.stop.duration",
        unit: {:native, :millisecond}
      ),

      # GraphRAG metrics
      summary("sorana.graph.build.stop.duration",
        unit: {:native, :millisecond}
      ),
      last_value("sorana.graph.build.stop.entity_count"),
      summary("sorana.graph.search.stop.duration",
        unit: {:native, :millisecond}
      ),
      last_value("sorana.graph.search.stop.graph_result_count")
    ]
  end
end
```

Configure LiveDashboard to use these metrics:

```elixir
# lib/my_app_web/router.ex
live_dashboard "/dashboard",
  metrics: MyApp.Telemetry
```

## Prometheus Integration

For production monitoring with Prometheus, use `prom_ex`:

```elixir
# mix.exs
{:prom_ex, "~> 1.9"}
```

```elixir
# lib/my_app/prom_ex.ex
defmodule MyApp.PromEx do
  use PromEx, otp_app: :my_app

  @impl true
  def plugins do
    [
      # Default plugins
      PromEx.Plugins.Application,
      PromEx.Plugins.Beam,
      # Add custom Sorana metrics
      MyApp.PromEx.SoranaPlugin
    ]
  end

  @impl true
  def dashboards do
    [
      {:prom_ex, "application.json"},
      {:prom_ex, "beam.json"}
    ]
  end
end
```

```elixir
# lib/my_app/prom_ex/sorana_plugin.ex
defmodule MyApp.PromEx.SoranaPlugin do
  use PromEx.Plugin

  @impl true
  def event_metrics(_opts) do
    Event.build(
      :sorana_event_metrics,
      [
        distribution(
          [:sorana, :search, :duration, :milliseconds],
          event_name: [:sorana, :search, :stop],
          measurement: :duration,
          unit: {:native, :millisecond},
          tags: [:mode],
          tag_values: fn metadata -> %{mode: metadata[:mode] || :semantic} end
        ),
        distribution(
          [:sorana, :llm, :complete, :duration, :milliseconds],
          event_name: [:sorana, :llm, :complete, :stop],
          measurement: :duration,
          unit: {:native, :millisecond},
          tags: [:model, :success],
          tag_values: fn metadata ->
            %{model: metadata[:model] || "unknown", success: metadata[:success]}
          end
        ),
        counter(
          [:sorana, :ingest, :chunks, :total],
          event_name: [:sorana, :ingest, :stop],
          measurement: fn _measurements, metadata -> metadata[:chunk_count] || 0 end
        )
      ]
    )
  end
end
```

## Debugging Performance Issues

### Identify Slow Operations

The built-in logger makes it easy to spot bottlenecks:

```
[info] [Sorana] embed completed in 45ms (384 dims)
[info] [Sorana] search completed in 12ms (10 results)
[info] [Sorana] llm.complete completed in 3.2s [openai:gpt-4o] ok (1892 chars)
[info] [Sorana] ask completed in 3.3s
```

In this example, the LLM call dominates total time (3.2s of 3.3s).

### Track Pipeline Steps

For `Sorana.Pipeline`, each step is instrumented:

```
[info] [Sorana] pipeline.gate completed in 150ms (skip_retrieval: false)
[info] [Sorana] pipeline.rewrite completed in 180ms ("what are elixir macros")
[info] [Sorana] pipeline.expand completed in 220ms ("elixir macros metaprogramming...")
[info] [Sorana] pipeline.search completed in 35ms (25 chunks)
[info] [Sorana] pipeline.reason completed in 850ms (1 iteration)
[info] [Sorana] pipeline.rerank completed in 890ms (8/25 kept)
[info] [Sorana] pipeline.answer completed in 2.1s
[info] [Sorana] pipeline.ground completed in 75ms (score: 0.92, 1 hallucinated span)
```

Here, reranking takes 890ms - if this is too slow, consider:
- Reducing chunks before reranking (lower search limit)
- Using a faster reranking threshold
- Implementing a custom reranker

If `reason/2` is taking too long due to multiple iterations, consider:
- Lowering `max_iterations` (default: 2)
- Improving initial search quality with query expansion

### Monitor LLM Costs

Track prompt sizes to estimate API costs:

```elixir
def handle_event([:sorana, :llm, :complete, :stop], measurements, metadata, _config) do
  # Rough token estimate (4 chars per token)
  prompt_tokens = div(metadata.prompt_length || 0, 4)
  response_tokens = div(metadata.response_length || 0, 4)

  Logger.info("LLM usage",
    model: metadata.model,
    prompt_tokens: prompt_tokens,
    response_tokens: response_tokens,
    success: metadata.success
  )
end
```

## Error Tracking

Handle exceptions to send to your error tracking service:

```elixir
def setup do
  exception_events = [
    [:sorana, :ingest, :exception],
    [:sorana, :search, :exception],
    [:sorana, :ask, :exception],
    [:sorana, :llm, :complete, :exception]
  ]

  :telemetry.attach_many("sorana-errors", exception_events, &handle_exception/4, nil)
end

def handle_exception(event, _measurements, metadata, _config) do
  # Send to Sentry, Honeybadger, etc.
  Sentry.capture_message("Sorana error",
    extra: %{
      event: inspect(event),
      kind: metadata.kind,
      reason: inspect(metadata.reason)
    }
  )
end
```

## Best Practices

1. **Start with the built-in logger** - It's zero-config and helps you understand what's happening

2. **Focus on LLM latency** - This is usually the bottleneck; track it closely

3. **Monitor reranking** - If using `Pipeline.rerank/2`, watch the kept/original ratio

4. **Track by collection** - Tag metrics with collection names to identify slow document sets

5. **Set up alerts** - Alert on LLM failures and unusually slow operations

6. **Log in production** - Keep at least `:info` level logging for Sorana to debug issues
