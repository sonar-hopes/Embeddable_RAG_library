defmodule Sorana.IngestWithCollectionTest do
  use Sorana.DataCase, async: true

  alias Sorana.Collection

  describe "ingest/2 with collection" do
    test "ingests document into default collection when no collection specified" do
      {:ok, document} = Sorana.ingest("Test content", repo: Sorana.TestRepo)

      document = Sorana.TestRepo.preload(document, :collection)
      assert document.collection.name == "default"
    end

    test "ingests document into specified collection by name" do
      {:ok, document} =
        Sorana.ingest("Test content", repo: Sorana.TestRepo, collection: "products")

      document = Sorana.TestRepo.preload(document, :collection)
      assert document.collection.name == "products"
    end

    test "ingests document into existing collection" do
      {:ok, collection} =
        %Collection{}
        |> Collection.changeset(%{name: "existing-collection"})
        |> Sorana.TestRepo.insert()

      {:ok, document} =
        Sorana.ingest("Test content", repo: Sorana.TestRepo, collection: "existing-collection")

      document = Sorana.TestRepo.preload(document, :collection)
      assert document.collection_id == collection.id
    end

    test "creates collection if it doesn't exist" do
      {:ok, document} =
        Sorana.ingest("Test content", repo: Sorana.TestRepo, collection: "new-collection")

      document = Sorana.TestRepo.preload(document, :collection)
      assert document.collection.name == "new-collection"
    end
  end

  describe "ingest_file/2 with collection" do
    test "ingests file into specified collection" do
      path = create_temp_file("File content", ".txt")

      {:ok, document} =
        Sorana.ingest_file(path, repo: Sorana.TestRepo, collection: "file-collection")

      document = Sorana.TestRepo.preload(document, :collection)
      assert document.collection.name == "file-collection"
    end

    test "defaults to default collection for files" do
      path = create_temp_file("File content", ".txt")

      {:ok, document} = Sorana.ingest_file(path, repo: Sorana.TestRepo)

      document = Sorana.TestRepo.preload(document, :collection)
      assert document.collection.name == "default"
    end
  end

  describe "search/2 with collection filter" do
    test "filters search results by collection" do
      {:ok, _} = Sorana.ingest("Elixir programming", repo: Sorana.TestRepo, collection: "docs")
      {:ok, _} = Sorana.ingest("Elixir syntax", repo: Sorana.TestRepo, collection: "tutorials")

      {:ok, docs_results} = Sorana.search("Elixir", repo: Sorana.TestRepo, collection: "docs")

      {:ok, tutorials_results} =
        Sorana.search("Elixir", repo: Sorana.TestRepo, collection: "tutorials")

      assert length(docs_results) == 1
      assert length(tutorials_results) == 1
    end

    test "returns all results when no collection filter" do
      {:ok, _} = Sorana.ingest("Elixir programming", repo: Sorana.TestRepo, collection: "docs")
      {:ok, _} = Sorana.ingest("Elixir syntax", repo: Sorana.TestRepo, collection: "tutorials")

      {:ok, results} = Sorana.search("Elixir", repo: Sorana.TestRepo)

      assert length(results) == 2
    end
  end

  defp create_temp_file(content, extension) do
    dir = System.tmp_dir!()
    filename = "arcana_test_#{:rand.uniform(100_000)}#{extension}"
    path = Path.join(dir, filename)
    File.write!(path, content)
    on_exit(fn -> File.rm(path) end)
    path
  end
end
