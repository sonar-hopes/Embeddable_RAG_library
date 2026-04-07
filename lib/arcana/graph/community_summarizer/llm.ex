defmodule Arcana.Graph.CommunitySummarizer.LLM do
  @moduledoc """
  LLM-based community summarizer.

  Uses a language model to generate natural language summaries of
  knowledge graph communities based on their entities and relationships.

  ## Configuration

      config :arcana, :graph,
        community_summarizer: {Arcana.Graph.CommunitySummarizer.LLM, llm: &MyApp.llm/3}

  ## Options

    - `:llm` - Required. A function `(prompt, context, opts) -> {:ok, response}`

  """

  @behaviour Arcana.Graph.CommunitySummarizer

  @impl true
  def summarize(entities, relationships, opts) do
    llm = Keyword.fetch!(opts, :llm)
    prompt = build_prompt(entities, relationships)

    :telemetry.span(
      [:arcana, :graph, :community_summary],
      %{entity_count: length(entities)},
      fn ->
        result = llm.(prompt, [], system_prompt: system_prompt())

        metadata =
          case result do
            {:ok, summary} -> %{summary_length: String.length(summary)}
            {:error, _} -> %{summary_length: 0}
          end

        {result, metadata}
      end
    )
  end

  @doc """
  Builds the prompt for community summarization.
  """
  def build_prompt(entities, relationships, opts \\ []) do
    graph_config = Arcana.Graph.config()
    max_entities = opts[:max_entities] || graph_config[:summary_max_entities] || 50

    max_relationships =
      opts[:max_relationships] || graph_config[:summary_max_relationships] || 100

    connection_counts = count_connections(entities, relationships)

    top_entities =
      entities
      |> Enum.sort_by(fn e -> Map.get(connection_counts, e.name, 0) end, :desc)
      |> Enum.take(max_entities)

    top_names = MapSet.new(top_entities, & &1.name)

    top_relationships =
      relationships
      |> Enum.filter(fn r ->
        MapSet.member?(top_names, r.source) or MapSet.member?(top_names, r.target)
      end)
      |> Enum.take(max_relationships)

    entity_section = format_entities(top_entities)
    relationship_section = format_relationships(top_relationships)

    """
    Generate a summary of the following knowledge graph community.

    # ENTITIES
    #{entity_section}

    # RELATIONSHIPS
    #{relationship_section}

    # TASK
    Write a 2-3 sentence summary that:
    1. Identifies the community's central theme or domain
    2. Names the most important entities (those with the most connections)
    3. Describes how the key entities relate to each other

    CRITICAL FORMATTING RULE: Start directly with the main subject/entity, never with meta-commentary.

    FORBIDDEN opening patterns (never use these):
    - "This community..." / "The community..."
    - "This group..." / "The group..."
    - "This network..." / "The network..."

    CORRECT example: "The Doctor travels through time with companions Rose and Clara, facing enemies like the Daleks across multiple regenerations."
    WRONG example: "This community centers on the Doctor Who universe, featuring the Doctor who travels..."

    Output only the summary paragraph, nothing else.
    """
  end

  defp count_connections(entities, relationships) do
    names = MapSet.new(entities, & &1.name)

    Enum.reduce(relationships, %{}, fn rel, acc ->
      acc
      |> then(fn a ->
        if MapSet.member?(names, rel.source), do: Map.update(a, rel.source, 1, &(&1 + 1)), else: a
      end)
      |> then(fn a ->
        if MapSet.member?(names, rel.target), do: Map.update(a, rel.target, 1, &(&1 + 1)), else: a
      end)
    end)
  end

  defp system_prompt do
    """
    You are a knowledge graph analyst performing information discovery.
    Your task is to write concise summaries of entity communities that will
    be used as context for answering user queries.

    Guidelines:
    - Only include information that is explicitly present in the provided data
    - Prioritize entities that have more relationships (they are more central)
    - Focus on factual descriptions, not speculation or interpretation
    - Write in a neutral, informative tone suitable for search context
    - NEVER start with "This community", "The community", or similar meta-phrases
    - Start directly with the main entity or subject matter
    """
  end

  defp format_entities([]), do: "No entities in this community."

  defp format_entities(entities) do
    Enum.map_join(entities, "\n", fn entity ->
      "- #{entity.name} (#{entity.type})"
    end)
  end

  defp format_relationships([]), do: "No relationships."

  defp format_relationships(relationships) do
    Enum.map_join(relationships, "\n", fn rel ->
      "- #{rel.source} --[#{rel.type}]--> #{rel.target}"
    end)
  end
end
