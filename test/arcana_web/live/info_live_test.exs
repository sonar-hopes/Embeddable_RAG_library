defmodule ArcanaWeb.InfoLiveTest do
  # async: false because two tests below mutate Application env for
  # `:arcana, :loop`, which is process-global and would race with any
  # parallel test that reads the same key.
  use ArcanaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  describe "Info page" do
    test "mounts successfully", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/arcana/info")

      assert html =~ "Configuration"
    end

    test "shows navigation with info tab active", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/arcana/info")

      assert has_element?(view, "a.arcana-tab.active[href='/arcana/info']")
    end

    test "shows repository configuration", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/arcana/info")

      assert html =~ "Repository"
    end

    test "shows embedding configuration", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/arcana/info")

      assert html =~ "Embedding"
    end

    test "shows LLM configuration", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/arcana/info")

      assert html =~ "LLM"
    end

    test "shows reranker configuration", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/arcana/info")

      assert html =~ "Reranker"
    end

    test "shows raw configuration", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/arcana/info")

      assert html =~ "Raw Configuration"
      assert html =~ "config :arcana"
    end

    test "shows Grounder section", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/arcana/info")

      assert html =~ "Grounder"
    end

    test "shows Loop section", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/arcana/info")

      assert html =~ "Loop"
    end

    test "Loop section reflects configured loop options", %{conn: conn} do
      original = Application.get_env(:arcana, :loop)

      Application.put_env(:arcana, :loop,
        max_iterations: 7,
        chunk_cap: 25,
        controller_llm: "zai:test"
      )

      try do
        {:ok, _view, html} = live(conn, "/arcana/info")

        assert html =~ "7"
        assert html =~ "25"
      after
        if original do
          Application.put_env(:arcana, :loop, original)
        else
          Application.delete_env(:arcana, :loop)
        end
      end
    end

    test "Loop section shows defaults when no :loop config is set", %{conn: conn} do
      original = Application.get_env(:arcana, :loop)
      Application.delete_env(:arcana, :loop)

      try do
        {:ok, _view, html} = live(conn, "/arcana/info")

        # Defaults: max_iterations 10, chunk_cap 30
        assert html =~ "Loop"
        assert html =~ "10"
        assert html =~ "30"
      after
        if original, do: Application.put_env(:arcana, :loop, original)
      end
    end
  end
end
