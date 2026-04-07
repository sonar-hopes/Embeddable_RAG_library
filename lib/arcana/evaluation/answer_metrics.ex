defmodule Arcana.Evaluation.AnswerMetrics do
  @moduledoc """
  Evaluates answer quality using LLM-as-judge.

  Two flavors are supported:

    * **Faithfulness** — does the answer only contain claims supported by
      the retrieved context? Catches hallucinations. Does not compare to
      any ground-truth answer.
    * **Correctness** — does the answer convey the same facts as a
      reference (ground-truth) answer? Catches wrong answers that happen
      to be faithful to the retrieved chunks. Requires a
      `reference_answer` on the test case.

  Use faithfulness when you have retrieved chunks but no ground truth.
  Use correctness when you have a ground-truth reference. Both are
  cheap LLM-as-judge calls; running them together is common.
  """

  alias Arcana.LLM

  @default_prompt """
  You are evaluating whether an answer is faithful to the provided context.

  Question: {question}

  Context (retrieved chunks):
  {chunks}

  Answer to evaluate:
  {answer}

  Rate the faithfulness of this answer on a scale of 0-10:
  - 0: Completely unfaithful, hallucinated, or contradicts the context
  - 5: Partially supported, some claims lack grounding
  - 10: Fully faithful, every claim is supported by the context

  Respond with JSON only:
  {"score": <0-10>, "reasoning": "<brief explanation>"}
  """

  @default_correctness_prompt """
  You are grading whether a candidate answer conveys the same facts as a reference answer.

  Question: {question}

  Reference answer (ground truth):
  {reference}

  Candidate answer:
  {answer}

  Rate how correct the candidate is relative to the reference on a scale of 0-10:
  - 0: Wrong or contradicts the reference
  - 5: Partially correct, some key facts missing or incorrect
  - 10: Fully correct, conveys the same core facts as the reference

  The candidate does not need to use the same wording. It needs to convey
  the same facts. Extra correct detail is fine. Missing key facts or
  incorrect facts lower the score.

  Respond with JSON only:
  {"score": <0-10>, "reasoning": "<brief explanation>"}
  """

  @doc """
  Returns the default faithfulness prompt template.
  """
  def default_prompt, do: @default_prompt

  @doc """
  Returns the default correctness prompt template.
  """
  def default_correctness_prompt, do: @default_correctness_prompt

  @doc """
  Evaluates the faithfulness of an answer to the retrieved chunks.

  ## Options

    * `:llm` - LLM function (required)
    * `:prompt` - Custom prompt function `fn question, chunks, answer -> prompt end`

  ## Returns

    * `{:ok, %{score: integer, reasoning: string | nil}}` on success
    * `{:error, reason}` on failure

  """
  def evaluate_faithfulness(question, chunks, answer, opts) do
    llm = Keyword.fetch!(opts, :llm)
    prompt_fn = Keyword.get(opts, :prompt, &default_prompt_fn/3)

    prompt = prompt_fn.(question, chunks, answer)

    case LLM.complete(llm, prompt, [], []) do
      {:ok, response} -> parse_response(response)
      {:error, _} = err -> err
    end
  end

  defp default_prompt_fn(question, chunks, answer) do
    chunks_text = Enum.map_join(chunks, "\n\n---\n\n", & &1.text)

    @default_prompt
    |> String.replace("{question}", question)
    |> String.replace("{chunks}", chunks_text)
    |> String.replace("{answer}", answer)
  end

  @doc """
  Scores a candidate answer against a reference answer via LLM-as-judge.

  This is a **correctness** check, not a faithfulness check. Use this
  when your test cases have ground-truth reference answers and you want
  to know "did the agent produce a correct answer" rather than just
  "did the agent stay grounded in whatever it retrieved."

  ## Options

    * `:llm` - LLM function (required)
    * `:prompt` - Custom prompt function `fn question, answer, reference -> prompt end`

  ## Returns

    * `{:ok, %{score: integer, reasoning: string | nil}}` on success
    * `{:error, reason}` on failure
  """
  def evaluate_correctness(question, answer, reference_answer, opts) do
    llm = Keyword.fetch!(opts, :llm)
    prompt_fn = Keyword.get(opts, :prompt, &default_correctness_prompt_fn/3)

    prompt = prompt_fn.(question, answer, reference_answer)

    case LLM.complete(llm, prompt, [], []) do
      {:ok, response} -> parse_response(response)
      {:error, _} = err -> err
    end
  end

  defp default_correctness_prompt_fn(question, answer, reference) do
    @default_correctness_prompt
    |> String.replace("{question}", question)
    |> String.replace("{reference}", reference)
    |> String.replace("{answer}", answer)
  end

  defp parse_response(response) do
    response
    |> strip_code_fence()
    |> JSON.decode()
    |> case do
      {:ok, %{"score" => score} = data} when is_number(score) ->
        {:ok,
         %{
           score: clamp_score(score),
           reasoning: data["reasoning"]
         }}

      {:ok, _} ->
        {:error, :invalid_response}

      {:error, _} ->
        {:error, :invalid_response}
    end
  end

  # Strip ```json ... ``` (or plain ```) markdown fences. Models like
  # glm-4.6 wrap JSON output in fenced code blocks even when the prompt
  # asks for "JSON only", which broke parse_response and silently
  # collapsed every faithfulness/correctness score to nil.
  defp strip_code_fence(text) do
    text
    |> String.trim()
    |> String.replace_prefix("```json", "")
    |> String.replace_prefix("```", "")
    |> String.replace_suffix("```", "")
    |> String.trim()
  end

  defp clamp_score(score) when score < 0, do: 0
  defp clamp_score(score) when score > 10, do: 10
  defp clamp_score(score), do: score
end
