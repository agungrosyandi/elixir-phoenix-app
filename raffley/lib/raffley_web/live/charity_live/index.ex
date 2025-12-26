defmodule RaffleyWeb.CharityLive.Index do
  use RaffleyWeb, :live_view

  alias Raffley.Charities

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Charities
        <:actions>
          <.button variant="primary" navigate={~p"/charities/new"}>
            <.icon name="hero-plus" /> New Charity
          </.button>
        </:actions>
      </.header>

      <.table
        id="charities"
        rows={@streams.charities}
        row_click={fn {_id, charity} -> JS.navigate(~p"/charities/#{charity}") end}
      >
        <:col :let={{_id, charity}} label="Name">{charity.name}</:col>
        <:col :let={{_id, charity}} label="Slug">{charity.slug}</:col>
        <:action :let={{_id, charity}}>
          <div class="sr-only">
            <.link navigate={~p"/charities/#{charity}"}>Show</.link>
          </div>
          <.link navigate={~p"/charities/#{charity}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, charity}}>
          <.link
            phx-click={JS.push("delete", value: %{id: charity.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Charities")
     |> stream(:charities, list_charities())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    charity = Charities.get_charity!(id)
    {:ok, _} = Charities.delete_charity(charity)

    {:noreply, stream_delete(socket, :charities, charity)}
  end

  defp list_charities() do
    Charities.list_charities()
  end
end
