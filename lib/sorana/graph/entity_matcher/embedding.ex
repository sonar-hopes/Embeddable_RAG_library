defmodule Sorana.Graph.EntityMatcher.Embedding do
  @moduledoc """
  Entity matcher that uses embedding similarity against entity descriptions.

  Embeds the query with the configured embedder, then searches the graph
  store for entities whose description embeddings are most similar via
  pgvector cosine distance.

  This is the default matcher and aligns with Microsoft GraphRAG's Local
  Search approach. It works best for conceptual or thematic queries where
  the query describes what you're looking for rather than naming it.

  ## Options

    * `:threshold` - minimum cosine similarity (default: 0.3)
    * `:limit` - maximum entities returned (default: 20)
    * `:repo` - Ecto repo (required)

  Requires entity embeddings to be populated. Run `mix arcana.graph.embed_entities`
  on existing graphs.
  """

  @behaviour Sorana.Graph.EntityMatcher

  alias Sorana.Graph.GraphStore

  @default_threshold 0.3
  @default_limit 20

  @impl Sorana.Graph.EntityMatcher
  def match(query, collection_ids, opts) do
    repo = Keyword.fetch!(opts, :repo)
    threshold = Keyword.get(opts, :threshold, @default_threshold)
    limit = Keyword.get(opts, :limit, @default_limit)

    embedder = Sorana.Config.embedder()

    case Sorana.Embedder.embed(embedder, query, intent: :query) do
      {:ok, query_embedding} ->
        results =
          GraphStore.search_by_embedding(query_embedding, collection_ids,
            repo: repo,
            limit: limit,
            threshold: threshold
          )

        {:ok, Enum.map(results, & &1.id)}

      {:error, _} = error ->
        error
    end
  end
end
