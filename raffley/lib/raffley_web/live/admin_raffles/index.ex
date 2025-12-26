defmodule RaffleyWeb.AdminRafflesLive.Index do
  use RaffleyWeb, :live_view

  alias Raffley.Admin
  import RaffleyWeb.CustomComponents

  def mount(_, _, socket) do
    socket =
      socket
      |> assign(:page_title, "Listing Raffles")
      |> stream(:raffles, Admin.list_raffles())

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="w-full rounded-xl p-5 border border-zinc-200  shadow-sm">
        <div class="border-b border-zinc-200 px-6 py-4">
          <.header>
            {@page_title}
            <:actions>
              <.link navigate={~p"/admin/raffles/new"} class="btn">
                New Raffles
              </.link>
            </:actions>
          </.header>
        </div>

        <div class="overflow-x-auto">
          <.table
            id="raffles"
            rows={@streams.raffles}
            row_click={fn {_, raffle} -> JS.navigate(~p"/raffles/#{raffle.id}") end}
          >
            <:col :let={{_, raffle}} label="Prize">
              <div class=" text-sky-600 underline-offset-2 hover:text-sky-800 hover:underline transition duration-150 ease-in-out">
                <.link navigate={~p"/raffles/#{raffle.id}"}>
                  {raffle.prize}
                </.link>
              </div>
            </:col>

            <:col :let={{_dom_id, raffle}} label="Status">
              <.badge status={raffle.status} />
            </:col>

            <:col :let={{_dom_id, raffle}} label="Ticket Price">
              {raffle.ticket_price}
            </:col>

            <:col :let={{_dom_id, raffle}} label="Winning Ticket Number">
              {raffle.winning_ticket_id}
            </:col>
            
    <!-- action -->

            <:action :let={{_, raffle}}>
              <.link navigate={~p"/admin/raffles/#{raffle.id}/edit"}>
                <button class="btn btn-info text-xs">
                  Edit
                </button>
              </.link>
            </:action>

            <:action :let={{dom_id, raffle}}>
              <.link phx-click={delete_and_hide(dom_id, raffle)} data-confirm="are you sure ?">
                <button class="btn btn-error text-xs">
                  Delete
                </button>
              </.link>
            </:action>

            <:action :let={{_dom_id, raffle}}>
              <.link phx-click="draw-winner" phx-value-id={raffle.id}>
                <button class="btn btn-success text-xs">
                  Draw&nbspWinner
                </button>
              </.link>
            </:action>
          </.table>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("delete", %{"id" => id}, socket) do
    raffle = Admin.get_raffle!(id)

    {:ok, _} = Admin.delete_raffle(raffle)

    {:noreply, stream_delete(socket, :raffles, raffle)}
  end

  def handle_event("draw-winner", %{"id" => id}, socket) do
    raffle = Admin.get_raffle!(id)

    case Admin.draw_winner(raffle) do
      {:ok, raffle} ->
        socket =
          socket
          |> put_flash(:info, "Winning Ticket draw!")
          |> stream_insert(:raffles, raffle)

        {:noreply, socket}

      {:error, error} ->
        {:noreply, put_flash(socket, :error, error)}
    end
  end

  def delete_and_hide(dom_id, raffle) do
    JS.push("delete", value: %{id: raffle.id})
    |> JS.add_class("opacity-50", to: "##{dom_id}", transition: "fade-out")
  end
end
