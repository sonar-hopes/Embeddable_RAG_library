defmodule Sorana.Agent do
  @moduledoc """
  Deprecated. Use `Sorana.Pipeline` instead.

  This module is a thin facade kept for backward compatibility. It will be
  removed in a future major version. All functions delegate to
  `Sorana.Pipeline` and emit compile-time deprecation warnings.

  ## Migration

      # Before
      Sorana.Agent.new(question)
      |> Sorana.Agent.search()
      |> Sorana.Agent.answer()

      # After
      Sorana.Pipeline.new(question)
      |> Sorana.Pipeline.search()
      |> Sorana.Pipeline.answer()

  Custom modules implementing the pipeline behaviours need to update
  their `@behaviour` declarations from `Sorana.Agent.*` to
  `Sorana.Pipeline.*`. The callbacks themselves are unchanged.
  """

  @deprecated "Use Sorana.Pipeline.new/2"
  defdelegate new(question, opts \\ []), to: Sorana.Pipeline

  @deprecated "Use Sorana.Pipeline.gate/2"
  defdelegate gate(ctx, opts \\ []), to: Sorana.Pipeline

  @deprecated "Use Sorana.Pipeline.rewrite/2"
  defdelegate rewrite(ctx, opts \\ []), to: Sorana.Pipeline

  @deprecated "Use Sorana.Pipeline.select/2"
  defdelegate select(ctx, opts), to: Sorana.Pipeline

  @deprecated "Use Sorana.Pipeline.expand/2"
  defdelegate expand(ctx, opts \\ []), to: Sorana.Pipeline

  @deprecated "Use Sorana.Pipeline.decompose/2"
  defdelegate decompose(ctx, opts \\ []), to: Sorana.Pipeline

  @deprecated "Use Sorana.Pipeline.search/2"
  defdelegate search(ctx, opts \\ []), to: Sorana.Pipeline

  @deprecated "Use Sorana.Pipeline.reason/2"
  defdelegate reason(ctx, opts \\ []), to: Sorana.Pipeline

  @deprecated "Use Sorana.Pipeline.rerank/2"
  defdelegate rerank(ctx, opts \\ []), to: Sorana.Pipeline

  @deprecated "Use Sorana.Pipeline.answer/2"
  defdelegate answer(ctx, opts \\ []), to: Sorana.Pipeline

  @deprecated "Use Sorana.Pipeline.ground/2"
  defdelegate ground(ctx, opts \\ []), to: Sorana.Pipeline
end
