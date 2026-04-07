defmodule Arcana.Ask do
  @moduledoc """
  RAG (Retrieval Augmented Generation) question answering.

  This module handles the core ask workflow:
  1. Search for relevant context chunks
  2. Build a prompt with the context
  3. Call the LLM for an answer

  ## Usage

      {:ok, answer, context} = Arcana.ask("What is X?",
        repo: MyApp.Repo,
        llm: "openai:gpt-4o-mini"
      )

  """

  alias Arcana.LLM

  @doc """
  Asks a question using retrieved context from the knowledge base.

  Performs a search to find relevant chunks, then passes them along with
  the question to an LLM for answer generation.

  ## Options

    * `:repo` - The Ecto repo to use (required)
    * `:llm` - Any type implementing the `Arcana.LLM` protocol (required)
    * `:limit` - Maximum number of context chunks to retrieve (default: 5)
    * `:source_id` - Filter context to a specific source
    * `:threshold` - Minimum similarity score for context (default: 0.0)
    * `:mode` - Search mode: `:semantic` (default), `:fulltext`, or `:hybrid`
    * `:collection` - Filter to a specific collection
    * `:collections` - Filter to multiple collections
    * `:prompt` - Custom prompt function `fn question, context -> system_prompt_string end`

  ## Examples

      # Basic usage
      {:ok, answer, context} = Arcana.ask("What is Elixir?",
        repo: MyApp.Repo,
        llm: "openai:gpt-4o-mini"
      )

      # With custom prompt
      {:ok, answer, _} = Arcana.ask("Summarize the docs",
        repo: MyApp.Repo,
        llm: my_llm,
        prompt: fn question, context ->
          "Be concise. Question: \#{question}"
        end
      )

  """
  def ask(question, opts) when is_binary(question) do
    repo = opts[:repo] || Application.get_env(:arcana, :repo)
    llm = opts[:llm] || Application.get_env(:arcana, :llm)

    if is_nil(llm), do: {:error, :no_llm_configured}, else: do_ask(question, opts, repo, llm)
  end

  defp do_ask(question, opts, repo, llm) do
    start_metadata = %{question: question, repo: repo}

    :telemetry.span([:arcana, :ask], start_metadata, fn ->
      search_opts =
        opts
        |> Keyword.take([
          :repo,
          :limit,
          :source_id,
          :threshold,
          :mode,
          :collection,
          :collections,
          :graph
        ])
        |> Keyword.put_new(:limit, 5)

      case Arcana.Search.search(question, search_opts) do
        {:ok, context} -> ask_with_context(question, context, opts, llm)
        {:error, reason} -> {{:error, {:search_failed, reason}}, %{error: reason}}
      end
    end)
  end

  defp ask_with_context(question, context, opts, llm) do
    community_summaries = maybe_fetch_community_context(question, opts)
    prompt_fn = Keyword.get(opts, :prompt, &default_ask_prompt/2)

    llm_opts = [
      system_prompt:
        case Function.info(prompt_fn, :arity) do
          {:arity, 3} -> prompt_fn.(question, context, community_summaries)
          {:arity, _} -> prompt_fn.(question, context)
        end
    ]

    result =
      case LLM.complete(llm, question, context, llm_opts) do
        {:ok, answer} -> {:ok, answer, context}
        {:error, reason} -> {:error, reason}
      end

    stop_metadata =
      case result do
        {:ok, answer, _} -> %{answer: answer, context_count: length(context)}
        {:error, _} -> %{context_count: length(context)}
      end

    {result, stop_metadata}
  end

  defp default_ask_prompt(question, context),
    do: default_ask_prompt(question, context, [])

  defp default_ask_prompt(_question, context, community_summaries) do
    context_text =
      Enum.map_join(context, "\n\n---\n\n", fn
        %{text: text} -> text
        text when is_binary(text) -> text
        other -> inspect(other)
      end)

    community_text =
      case community_summaries do
        [] ->
          ""

        summaries ->
          text = Enum.map_join(summaries, "\n\n", & &1)

          """

          Background knowledge:
          #{text}
          """
      end

    if context_text != "" do
      """
      Answer the user's question based on the following context.
      If the answer is not in the context, say you don't know.
      #{community_text}
      Context:
      #{context_text}
      """
    else
      "You are a helpful assistant."
    end
  end

  defp maybe_fetch_community_context(question, opts) do
    repo = opts[:repo] || Application.get_env(:arcana, :repo)

    if Arcana.Config.graph_enabled?(opts) and repo do
      fetch_community_summaries(question, repo, opts)
    else
      []
    end
  end

  defp fetch_community_summaries(question, repo, opts) do
    import Ecto.Query
    alias Arcana.Graph.{Entity, EntityExtractor}

    entity_extractor = Arcana.Graph.resolve_entity_extractor(opts)

    with {:ok, entities} when entities != [] <-
           EntityExtractor.extract(entity_extractor, question) do
      entity_names = Enum.map(entities, & &1.name)

      collections =
        cond do
          Keyword.has_key?(opts, :collections) -> Keyword.get(opts, :collections)
          Keyword.has_key?(opts, :collection) -> [Keyword.get(opts, :collection)]
          true -> [nil]
        end

      collection_ids =
        collections
        |> Enum.reject(&is_nil/1)
        |> Enum.flat_map(fn name ->
          case repo.one(from(c in Arcana.Collection, where: c.name == ^name, select: c.id)) do
            nil -> []
            id -> [id]
          end
        end)

      entity_ids =
        if collection_ids != [] do
          repo.all(
            from(e in Entity,
              where: e.name in ^entity_names and e.collection_id in ^collection_ids,
              select: e.id
            )
          )
        else
          repo.all(from(e in Entity, where: e.name in ^entity_names, select: e.id))
        end

      if entity_ids != [] do
        uuid_list = Enum.map_join(entity_ids, ",", &"'#{&1}'")
        graph_config = Arcana.Graph.config()
        summary_level = graph_config[:community_summary_level] || 0
        summary_limit = graph_config[:community_summary_limit] || 5

        {:ok, %{rows: rows}} =
          Ecto.Adapters.SQL.query(
            repo,
            "SELECT summary FROM arcana_graph_communities WHERE entity_ids && ARRAY[#{uuid_list}]::uuid[] AND summary IS NOT NULL AND summary != '' AND level = #{summary_level} LIMIT #{summary_limit}",
            []
          )

        Enum.map(rows, fn [summary] -> summary end)
      else
        []
      end
    else
      _ -> []
    end
  end
end
