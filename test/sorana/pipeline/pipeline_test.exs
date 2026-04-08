defmodule Sorana.Pipeline.PipelineTest do
  use Sorana.DataCase, async: true

  alias Sorana.Pipeline

  describe "pipeline" do
    setup do
      # Use words that will overlap with the query for mock embeddings
      # Mock embeddings use word hashes, so shared words = higher similarity
      {:ok, _doc} =
        Sorana.ingest("Elixir is a functional programming language that runs on BEAM.",
          repo: Sorana.TestRepo
        )

      :ok
    end

    test "full pipeline from question to answer" do
      llm = fn prompt ->
        if prompt =~ "BEAM" do
          {:ok, "Elixir runs on the BEAM VM."}
        else
          {:ok, "Unknown"}
        end
      end

      # Query shares "Elixir", "programming", "language" with document
      # Explicitly disable graph to avoid race with tests that enable it globally
      ctx =
        Pipeline.new("What programming language is Elixir?",
          repo: Sorana.TestRepo,
          llm: llm,
          graph: false
        )
        |> Pipeline.search()
        |> Pipeline.answer()

      assert ctx.answer == "Elixir runs on the BEAM VM."
      refute Enum.empty?(ctx.results)
      refute Enum.empty?(ctx.context_used)
    end
  end

  describe "telemetry" do
    setup do
      {:ok, _doc} = Sorana.ingest("Telemetry test content", repo: Sorana.TestRepo)
      :ok
    end

    test "emits telemetry events for search" do
      ref = make_ref()
      test_pid = self()

      :telemetry.attach_many(
        ref,
        [
          [:arcana, :pipeline, :search, :start],
          [:arcana, :pipeline, :search, :stop]
        ],
        fn event, measurements, metadata, _ ->
          send(test_pid, {:telemetry, event, measurements, metadata})
        end,
        nil
      )

      Pipeline.new("test", repo: Sorana.TestRepo, llm: &mock_llm/1)
      |> Pipeline.search()

      assert_receive {:telemetry, [:arcana, :pipeline, :search, :start], _, _}
      assert_receive {:telemetry, [:arcana, :pipeline, :search, :stop], _, metadata}
      assert is_integer(metadata.result_count)

      :telemetry.detach(ref)
    end

    test "emits telemetry events for answer" do
      ref = make_ref()
      test_pid = self()

      :telemetry.attach_many(
        ref,
        [
          [:arcana, :pipeline, :answer, :start],
          [:arcana, :pipeline, :answer, :stop]
        ],
        fn event, measurements, metadata, _ ->
          send(test_pid, {:telemetry, event, measurements, metadata})
        end,
        nil
      )

      llm = fn _prompt -> {:ok, "Answer"} end

      Pipeline.new("test", repo: Sorana.TestRepo, llm: llm)
      |> Pipeline.search()
      |> Pipeline.answer()

      assert_receive {:telemetry, [:arcana, :pipeline, :answer, :start], _, _}
      assert_receive {:telemetry, [:arcana, :pipeline, :answer, :stop], _, metadata}
      assert is_integer(metadata.context_chunk_count)

      :telemetry.detach(ref)
    end
  end

  defp mock_llm(_prompt), do: {:ok, "mock response"}
end
