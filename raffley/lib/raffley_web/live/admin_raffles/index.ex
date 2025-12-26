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
      <div class="relative">
        <.header>
          {@page_title}
          <:actions>
            <.link navigate={~p"/admin/raffles/new"} class="button">
              New Raffles
            </.link>
          </:actions>
        </.header>

        <div class="relative mt-10 overflow-hidden w-full flex flex-col p-5 rounded-xl border border-gray-200 bg-white shadow-sm">
          <.table
            id="raffles"
            rows={@streams.raffles}
            row_click={fn {_, raffle} -> JS.navigate(~p"/raffles/#{raffle.id}") end}
          >
            <:col :let={{_, raffle}} label="Prize">
              <div class="p-2 text-sky-600 underline-offset-2 hover:text-sky-800 hover:underline transition duration-150 ease-in-out">
                <.link navigate={~p"/raffles/#{raffle.id}"}>
                  {raffle.prize}
                </.link>
              </div>
            </:col>

            <:col :let={{_, raffle}} label="Status">
              <div class="p-2">
                <.badge status={raffle.status} />
              </div>
            </:col>

            <:col :let={{_, raffle}} label="Ticket Price">
              <div class="p-2">
                {raffle.ticket_price}
              </div>
            </:col>

            <:col :let={{_dom_id, raffle}} label="Winning Ticket Number">
              <div class="p-2">
                {raffle.winning_ticket_id}
              </div>
            </:col>
            
    <!-- action -->

            <:action :let={{_, raffle}}>
              <.link navigate={~p"/admin/raffles/#{raffle.id}/edit"}> Edit</.link>
            </:action>

            <:action :let={{dom_id, raffle}}>
              <.link phx-click={delete_and_hide(dom_id, raffle)} data-confirm="are you sure ?">
                Delete
              </.link>
            </:action>

            <:action :let={{_dom_id, raffle}}>
              <.link phx-click="draw-winner" phx-value-id={raffle.id}>
                Draw Winner
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
