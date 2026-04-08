defmodule Sorana.Pipeline.SearchTest do
  use Sorana.DataCase, async: true

  alias Sorana.Pipeline
  alias Sorana.Pipeline.Context

  describe "search/2" do
    setup do
      {:ok, _doc} =
        Sorana.ingest("Elixir is a functional programming language.",
          repo: Sorana.TestRepo
        )

      :ok
    end

    test "searches and populates results" do
      ctx =
        Pipeline.new("functional programming", repo: Sorana.TestRepo, llm: &mock_llm/1)
        |> Pipeline.search()

      assert is_list(ctx.results)
      refute Enum.empty?(ctx.results)

      [first | _] = ctx.results
      assert first.question == "functional programming"
      assert first.collection == "default"
      assert is_list(first.chunks)
    end

    test "respects limit option" do
      ctx =
        Pipeline.new("programming", repo: Sorana.TestRepo, llm: &mock_llm/1, limit: 1)
        |> Pipeline.search()

      [result | _] = ctx.results
      assert length(result.chunks) <= 1
    end

    test "uses sub_questions if present" do
      ctx =
        %Context{
          question: "original",
          repo: Sorana.TestRepo,
          llm: &mock_llm/1,
          limit: 5,
          threshold: 0.5,
          sub_questions: ["Elixir", "functional"]
        }
        |> Pipeline.search()

      assert length(ctx.results) == 2
      questions = Enum.map(ctx.results, & &1.question)
      assert "Elixir" in questions
      assert "functional" in questions
    end

    test "uses collections if present" do
      # Create a document in a specific collection
      {:ok, _} =
        Sorana.ingest("Python is also great.",
          repo: Sorana.TestRepo,
          collection: "other-langs"
        )

      ctx =
        %Context{
          question: "programming",
          repo: Sorana.TestRepo,
          llm: &mock_llm/1,
          limit: 5,
          threshold: 0.5,
          collections: ["default", "other-langs"]
        }
        |> Pipeline.search()

      # Should have results for each collection
      collections = Enum.map(ctx.results, & &1.collection)
      assert "default" in collections
      assert "other-langs" in collections
    end

    test "uses :collection option to search specific collection" do
      {:ok, _} =
        Sorana.ingest("Ruby is a programming language.",
          repo: Sorana.TestRepo,
          collection: "ruby-docs"
        )

      ctx =
        Pipeline.new("programming", repo: Sorana.TestRepo, llm: &mock_llm/1)
        |> Pipeline.search(collection: "ruby-docs")

      # Should only search the specified collection
      assert length(ctx.results) == 1
      [result] = ctx.results
      assert result.collection == "ruby-docs"
    end

    test "uses :collections option to search multiple collections" do
      {:ok, _} =
        Sorana.ingest("Go is a systems language.",
          repo: Sorana.TestRepo,
          collection: "go-docs"
        )

      {:ok, _} =
        Sorana.ingest("Rust is memory safe.",
          repo: Sorana.TestRepo,
          collection: "rust-docs"
        )

      ctx =
        Pipeline.new("language", repo: Sorana.TestRepo, llm: &mock_llm/1)
        |> Pipeline.search(collections: ["go-docs", "rust-docs"])

      # Should search both collections
      collections = Enum.map(ctx.results, & &1.collection)
      assert "go-docs" in collections
      assert "rust-docs" in collections
    end

    test "option takes priority over ctx.collections" do
      {:ok, _} =
        Sorana.ingest("Haskell is purely functional.",
          repo: Sorana.TestRepo,
          collection: "haskell-docs"
        )

      ctx =
        %Context{
          question: "functional",
          repo: Sorana.TestRepo,
          llm: &mock_llm/1,
          limit: 5,
          threshold: 0.5,
          collections: ["default"]
        }
        |> Pipeline.search(collection: "haskell-docs")

      # Option should override ctx.collections
      assert length(ctx.results) == 1
      [result] = ctx.results
      assert result.collection == "haskell-docs"
    end

    test "skips search when skip_retrieval is true" do
      ctx =
        %Context{
          question: "What is 2 + 2?",
          repo: Sorana.TestRepo,
          llm: &mock_llm/1,
          limit: 5,
          threshold: 0.5,
          skip_retrieval: true
        }
        |> Pipeline.search()

      # Should not have searched - results should be empty
      assert ctx.results == []
    end

    test "performs search when skip_retrieval is false" do
      ctx =
        %Context{
          question: "functional programming",
          repo: Sorana.TestRepo,
          llm: &mock_llm/1,
          limit: 5,
          threshold: 0.5,
          skip_retrieval: false
        }
        |> Pipeline.search()

      # Should have searched
      refute Enum.empty?(ctx.results)
    end

    test "performs search when skip_retrieval is nil (default)" do
      ctx =
        Pipeline.new("functional programming", repo: Sorana.TestRepo, llm: &mock_llm/1)
        |> Pipeline.search()

      # Default behavior - should search
      refute Enum.empty?(ctx.results)
    end
  end

  describe "custom searcher" do
    test "accepts custom searcher module" do
      defmodule TestSearcher do
        @behaviour Sorana.Searcher

        @impl true
        def search(_question, _collection, _opts) do
          chunks = [
            %{id: "custom-1", text: "Custom search result", metadata: %{}, similarity: 0.9}
          ]

          {:ok, chunks}
        end
      end

      ctx =
        Pipeline.new("anything", repo: Sorana.TestRepo, llm: &mock_llm/1)
        |> Pipeline.search(searcher: TestSearcher)

      [result | _] = ctx.results
      [chunk | _] = result.chunks
      assert chunk.id == "custom-1"
      assert chunk.text == "Custom search result"
    end

    test "accepts custom searcher function" do
      custom_searcher = fn question, _collection, _opts ->
        {:ok,
         [%{id: "fn-1", text: "Function search: #{question}", metadata: %{}, similarity: 1.0}]}
      end

      ctx =
        Pipeline.new("test query", repo: Sorana.TestRepo, llm: &mock_llm/1)
        |> Pipeline.search(searcher: custom_searcher)

      [result | _] = ctx.results
      [chunk | _] = result.chunks
      assert chunk.id == "fn-1"
      assert chunk.text =~ "test query"
    end

    test "returns empty results on searcher error" do
      custom_searcher = fn _question, _collection, _opts ->
        {:error, :search_failed}
      end

      ctx =
        Pipeline.new("test", repo: Sorana.TestRepo, llm: &mock_llm/1)
        |> Pipeline.search(searcher: custom_searcher)

      [result | _] = ctx.results
      assert result.chunks == []
    end
  end

  defp mock_llm(_prompt), do: {:ok, "mock response"}
end
