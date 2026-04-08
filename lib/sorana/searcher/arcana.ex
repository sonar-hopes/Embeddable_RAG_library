defmodule Sorana.Searcher.Sorana do
  @moduledoc """
  Default searcher using Sorana's built-in pgvector search.

  Uses `Sorana.search/2` to perform semantic similarity search against
  the configured PostgreSQL database with pgvector.

  ## Usage

      # With Sorana.Pipeline (this is the default)
      ctx
      |> Pipeline.search()
      |> Pipeline.answer()

      # Explicitly specifying the searcher
      ctx
      |> Pipeline.search(searcher: Sorana.Searcher.Sorana)
      |> Pipeline.answer()

  ## Options

  - `:repo` - The Ecto repo (required)
  - `:collection` - Collection name to search
  - `:limit` - Maximum chunks to return (default: 5)
  - `:threshold` - Minimum similarity threshold (default: 0.5)
  """

  @behaviour Sorana.Searcher

  @impl Sorana.Searcher
  def search(question, collection, opts) do
    repo = Keyword.fetch!(opts, :repo)
    limit = Keyword.get(opts, :limit, 5)
    threshold = Keyword.get(opts, :threshold, 0.5)

    Sorana.search(question,
      repo: repo,
      collection: collection,
      limit: limit,
      threshold: threshold
    )
  end
end
