defmodule Sorana.Graph.EntityMatcher do
  @moduledoc """
  Behaviour for matching query text to entities in the graph.

  Used by `Sorana.Search` and `Sorana.Ask` during graph-enhanced retrieval
  to find entities relevant to a query. The returned entity IDs are then
  used to fetch related chunks via the entity_mentions table.

  ## Built-in Implementations

    * `Sorana.Graph.EntityMatcher.Embedding` (default) - cosine similarity
      against entity description embeddings. Best for conceptual queries.
    * `Sorana.Graph.EntityMatcher.NER` - extract entity names from the query
      (via `Sorana.Graph.EntityExtractor`) and look them up by exact match.
      Best when queries name entities directly.

  ## Configuration

      # Global default (shortcut atom or module)
      config :arcana, graph: [entity_matcher: :ner]
      config :arcana, graph: [entity_matcher: Sorana.Graph.EntityMatcher.NER]

      # With options
      config :arcana, graph: [
        entity_matcher: {Sorana.Graph.EntityMatcher.Embedding, threshold: 0.5}
      ]

      # Per-call override
      Sorana.search(query, graph: true, entity_matcher: :ner)

  ## Custom implementations

      defmodule MyApp.SmartMatcher do
        @behaviour Sorana.Graph.EntityMatcher

        @impl true
        def match(query, collection_ids, opts) do
          # Your logic, returning {:ok, [entity_id]} or {:error, reason}
        end
      end

      config :arcana, graph: [entity_matcher: MyApp.SmartMatcher]

  """

  @doc """
  Matches a query to entity IDs in the graph.

  ## Parameters

    * `query` - the query text
    * `collection_ids` - optional list of collection UUIDs to scope the search,
      or `nil` for all collections
    * `opts` - keyword list including at least `:repo`. Implementations may
      accept their own options like `:threshold` and `:limit`.

  Returns `{:ok, entity_ids}` (possibly empty) or `{:error, reason}`.
  """
  @callback match(
              query :: String.t(),
              collection_ids :: [binary()] | nil,
              opts :: keyword()
            ) :: {:ok, [binary()]} | {:error, term()}
end
