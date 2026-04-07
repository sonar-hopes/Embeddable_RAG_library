defmodule Arcana.Evaluation.AnswerMetricsTest do
  use ExUnit.Case, async: true

  alias Arcana.Evaluation.AnswerMetrics

  describe "evaluate_faithfulness/4" do
    test "returns score and reasoning for faithful answer" do
      chunks = [
        %{text: "Elixir is a functional programming language that runs on the BEAM VM."},
        %{text: "Elixir was created by José Valim in 2011."}
      ]

      question = "What is Elixir?"
      answer = "Elixir is a functional programming language that runs on the BEAM VM."

      llm = fn _prompt ->
        {:ok, ~s({"score": 9, "reasoning": "Answer directly quotes the context."})}
      end

      {:ok, result} = AnswerMetrics.evaluate_faithfulness(question, chunks, answer, llm: llm)

      assert result.score == 9
      assert result.reasoning == "Answer directly quotes the context."
    end

    test "returns low score for hallucinated answer" do
      chunks = [
        %{text: "Elixir is a functional programming language."}
      ]

      question = "What is Elixir?"
      answer = "Elixir was created by Guido van Rossum and is used for machine learning."

      llm = fn _prompt ->
        {:ok,
         ~s({"score": 2, "reasoning": "Answer contains hallucinated information not in context."})}
      end

      {:ok, result} = AnswerMetrics.evaluate_faithfulness(question, chunks, answer, llm: llm)

      assert result.score == 2
      assert result.reasoning =~ "hallucinated"
    end

    test "handles LLM error gracefully" do
      llm = fn _prompt -> {:error, :api_error} end

      result = AnswerMetrics.evaluate_faithfulness("Q?", [%{text: "..."}], "A", llm: llm)

      assert {:error, :api_error} = result
    end

    test "handles malformed JSON response" do
      llm = fn _prompt -> {:ok, "not valid json"} end

      result = AnswerMetrics.evaluate_faithfulness("Q?", [%{text: "..."}], "A", llm: llm)

      assert {:error, :invalid_response} = result
    end

    test "handles JSON without required fields" do
      llm = fn _prompt -> {:ok, ~s({"score": 5})} end

      {:ok, result} = AnswerMetrics.evaluate_faithfulness("Q?", [%{text: "..."}], "A", llm: llm)

      assert result.score == 5
      assert result.reasoning == nil
    end

    test "clamps score to 0-10 range" do
      llm = fn _prompt -> {:ok, ~s({"score": 15, "reasoning": "test"})} end

      {:ok, result} = AnswerMetrics.evaluate_faithfulness("Q?", [%{text: "..."}], "A", llm: llm)

      assert result.score == 10
    end

    test "strips ```json markdown code fences from the LLM response" do
      # glm-4.6 (and most chat-tuned models) wrap JSON in fenced code blocks
      # even when the prompt asks for "JSON only". Pre-fix this collapsed
      # every faithfulness/correctness score to nil silently.
      fenced = """
      ```json
      {"score": 8, "reasoning": "wrapped in a fence"}
      ```
      """

      llm = fn _prompt -> {:ok, fenced} end

      {:ok, result} = AnswerMetrics.evaluate_faithfulness("Q?", [%{text: "..."}], "A", llm: llm)

      assert result.score == 8
      assert result.reasoning == "wrapped in a fence"
    end

    test "strips a plain ``` fence with no language tag" do
      fenced = "```\n{\"score\": 6, \"reasoning\": \"no lang tag\"}\n```"
      llm = fn _prompt -> {:ok, fenced} end

      {:ok, result} = AnswerMetrics.evaluate_faithfulness("Q?", [%{text: "..."}], "A", llm: llm)

      assert result.score == 6
    end

    test "accepts custom prompt function" do
      custom_prompt = fn question, _chunks, _answer ->
        "Custom prompt for: #{question}"
      end

      llm = fn prompt ->
        send(self(), {:prompt, prompt})
        {:ok, ~s({"score": 8, "reasoning": "ok"})}
      end

      {:ok, _result} =
        AnswerMetrics.evaluate_faithfulness("Q?", [%{text: "..."}], "A",
          llm: llm,
          prompt: custom_prompt
        )

      assert_receive {:prompt, "Custom prompt for: Q?"}
    end
  end

  describe "default_prompt/0" do
    test "returns the default faithfulness prompt template" do
      prompt = AnswerMetrics.default_prompt()

      assert prompt =~ "{question}"
      assert prompt =~ "{chunks}"
      assert prompt =~ "{answer}"
      assert prompt =~ "faithfulness"
    end
  end

  describe "evaluate_correctness/4" do
    test "scores an answer against a reference answer via LLM-as-judge" do
      question = "What is Elixir?"
      answer = "Elixir is a functional programming language built on the BEAM VM."
      reference = "Elixir is a functional language that runs on the Erlang VM (BEAM)."

      llm = fn prompt ->
        # The prompt should mention both the generated answer and the reference
        send(self(), {:prompt, prompt})
        {:ok, ~s({"score": 9, "reasoning": "Both convey the same core facts."})}
      end

      {:ok, result} = AnswerMetrics.evaluate_correctness(question, answer, reference, llm: llm)

      assert result.score == 9
      assert result.reasoning =~ "same core"

      assert_receive {:prompt, prompt}
      assert prompt =~ "Elixir is a functional programming"
      assert prompt =~ "Erlang VM"
    end

    test "returns low score when the answer contradicts the reference" do
      llm = fn _prompt ->
        {:ok, ~s({"score": 1, "reasoning": "Answer names the wrong creator and wrong year."})}
      end

      {:ok, result} =
        AnswerMetrics.evaluate_correctness(
          "Who created Python?",
          "Python was created by Linus Torvalds in 2005.",
          "Python was created by Guido van Rossum in 1991.",
          llm: llm
        )

      assert result.score == 1
      assert result.reasoning =~ "wrong"
    end

    test "handles LLM errors" do
      llm = fn _prompt -> {:error, :timeout} end

      assert {:error, :timeout} =
               AnswerMetrics.evaluate_correctness("q", "a", "ref", llm: llm)
    end

    test "handles malformed JSON" do
      llm = fn _prompt -> {:ok, "not json"} end

      assert {:error, :invalid_response} =
               AnswerMetrics.evaluate_correctness("q", "a", "ref", llm: llm)
    end

    test "clamps score to 0-10 range" do
      llm = fn _prompt -> {:ok, ~s({"score": 42})} end
      {:ok, result} = AnswerMetrics.evaluate_correctness("q", "a", "ref", llm: llm)
      assert result.score == 10
    end

    test "accepts a custom prompt function" do
      custom_prompt = fn question, answer, reference ->
        "grade: #{question} / #{answer} / #{reference}"
      end

      llm = fn prompt ->
        send(self(), {:prompt, prompt})
        {:ok, ~s({"score": 5})}
      end

      {:ok, _} =
        AnswerMetrics.evaluate_correctness("q", "a", "ref",
          llm: llm,
          prompt: custom_prompt
        )

      assert_receive {:prompt, "grade: q / a / ref"}
    end
  end
end
