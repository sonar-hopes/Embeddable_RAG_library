defmodule SoranaWeb.DashboardLive do
  @moduledoc """
  Redirects to the Documents page.

  This module previously contained the monolithic dashboard with tab switching.
  It has been replaced by separate LiveView pages for each tab:

  - `/documents` - SoranaWeb.DocumentsLive
  - `/collections` - SoranaWeb.CollectionsLive
  - `/search` - SoranaWeb.SearchLive
  - `/ask` - SoranaWeb.AskLive
  - `/evaluation` - SoranaWeb.EvaluationLive
  - `/maintenance` - SoranaWeb.MaintenanceLive
  - `/info` - SoranaWeb.InfoLive
  """
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: false}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <script>window.location.href = window.location.pathname + "/documents";</script>
    """
  end
end
