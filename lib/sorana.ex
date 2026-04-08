defmodule Sorana do
  @moduledoc """
  RAG (Retrieval Augmented Generation) library for Elixir.

  Sorana provides document ingestion, embedding, and vector search
  capabilities that you can embed into any Phoenix/Ecto application.

  ## Usage

      # Ingest a document
      {:ok, document} = Sorana.ingest("Your text content", repo: MyApp.Repo)

      # Search for relevant chunks
      {:ok, results} = Sorana.search("your query", repo: MyApp.Repo)

      # Ask questions with RAG
      {:ok, answer} = Sorana.ask("What is X?", repo: MyApp.Repo, llm: my_llm)

      # Delete a document
      :ok = Sorana.delete(document.id, repo: MyApp.Repo)

  ## Modules

    * `Sorana.Config` - Configuration management
    * `Sorana.Ingest` - Document ingestion
    * `Sorana.Search` - Vector and hybrid search
    * `Sorana.Ask` - RAG question answering
    * `Sorana.Graph` - GraphRAG functionality

  """

  alias Sorana.Document

  # === Configuration ===

  @doc """
  Returns the configured embedder as a `{module, opts}` tuple.
  See `Sorana.Config` for configuration options.
  """
  defdelegate embedder, to: Sorana.Config

  @doc """
  Returns the configured chunker as a `{module, opts}` tuple.
  See `Sorana.Config` for configuration options.
  """
  defdelegate chunker, to: Sorana.Config

  @doc """
  Returns the current Sorana configuration.
  """
  def config, do: Sorana.Config.current()

  @doc """
  Returns whether GraphRAG is enabled.
  """
  defdelegate graph_enabled?(opts), to: Sorana.Config

  # === Ingestion ===

  @doc """
  Ingests text content, creating a document with embedded chunks.
  See `Sorana.Ingest.ingest/2` for options.
  """
  defdelegate ingest(text, opts), to: Sorana.Ingest

  @doc """
  Ingests a file, parsing its content and creating a document with embedded chunks.
  See `Sorana.Ingest.ingest_file/2` for options.
  """
  defdelegate ingest_file(path, opts), to: Sorana.Ingest

  # === Search ===

  @doc """
  Searches for chunks similar to the query.
  See `Sorana.Search.search/2` for options.
  """
  defdelegate search(query, opts), to: Sorana.Search

  @doc """
  Rewrites a query using a provided rewriter function.
  See `Sorana.Search.rewrite_query/2` for options.
  """
  defdelegate rewrite_query(query, opts \\ []), to: Sorana.Search

  # === RAG Q&A ===

  @doc """
  Asks a question using retrieved context from the knowledge base.
  See `Sorana.Ask.ask/2` for options.
  """
  defdelegate ask(question, opts), to: Sorana.Ask

  # === Document Management ===

  @doc """
  Deletes a document and all its chunks.

  ## Options

    * `:repo` - The Ecto repo to use (required)

  """
  def delete(document_id, opts) do
    repo =
      opts[:repo] || Application.get_env(:sorana, :repo) ||
        raise ArgumentError, "repo is required"

    case repo.get(Document, document_id) do
      nil -> {:error, :not_found}
      document -> repo.delete!(document) && :ok
    end
  end
end
