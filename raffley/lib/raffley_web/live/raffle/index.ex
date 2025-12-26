defmodule RaffleyWeb.RafflesLive.Index do
  use RaffleyWeb, :live_view

  alias Raffley.Raffles
  alias Raffley.Charities
  import RaffleyWeb.CustomComponents

  # MOUNT

  def mount(_params, _sessions, socket) do
    socket = assign(socket, :charity_options, Charities.charity_names_and_slugs())

    {:ok, socket}
  end

  def handle_params(params, _, socket) do
    socket =
      socket
      |> stream(:raffles, Raffles.filter_raffles(params), reset: true)
      |> assign(:form, to_form(params))

    {:noreply, socket}
  end

  # RENDER

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="raffle-index">
        <.banner>
          <.icon name="hero-sparkles-solid" /> Mystery raffle comming soon
          <:details :let={vibe}>To be revealed tommorow {vibe}</:details>
          <:details>any question ?</:details>
        </.banner>

        <.filter_form form={@form} charity_options={@charity_options} />

        <div class="raffles" id="raffles" phx-update="stream">
          <.raffle_card :for={{dom_id, raffle} <- @streams.raffles} raffle={raffle} id={dom_id} />
        </div>
      </div>
    </Layouts.app>
    """
  end

  # HANDLE LOGIC

  # -------------------------------------------------------------------------

  def filter_form(assigns) do
    ~H"""
    <.form for={@form} id="filter-form" phx-change="filter">
      
    <!-- query search -->

      <.input
        class="border p-2 rounded-lg"
        field={@form[:q]}
        placeholder="Search ...."
        autocomplete="off"
        phx-debounce="500"
      />
      
    <!-- sort by upcoming, open, closed -->

      <.input
        class="border p-2 rounded-lg"
        type="select"
        field={@form[:status]}
        prompt="Status"
        options={[:upcoming, :open, :closed]}
      />
      
    <!-- sort by charity -->

      <.input
        class="border p-2 rounded-lg"
        type="select"
        field={@form[:charity]}
        prompt="Charity"
        options={@charity_options}
      />
      
    <!-- sort by prize and ticket price filter -->

      <.input
        class="border p-2 rounded-lg"
        type="select"
        field={@form[:sort_by]}
        prompt="Sort By"
        options={[
          Prize: "prize",
          "Price: High to Low": "ticket_price_desc",
          "Price: Low to High": "ticket_price_asc",
          Charity: "charity"
        ]}
      />

      <.link patch={~p"/raffles"}>reset</.link>
    </.form>
    """
  end

  # -------------------------------------------------------------------------

  attr(:raffle, Raffley.Raffles.Raffle, required: true)
  attr(:id, :string, required: true)

  def raffle_card(assigns) do
    ~H"""
    <.link navigate={~p"/raffles/#{@raffle.id}"} id={@id}>
      <div class="card">
        <div class="charity">
          {@raffle.charity.name}
        </div>
        <img src={@raffle.image_path} alt="" srcset="" />
        <h2 class="">{@raffle.prize}</h2>
        <div class="details">
          <div class="price">
            ${@raffle.ticket_price} / Ticket
          </div>
          <.badge status={@raffle.status} />
        </div>
      </div>
    </.link>
    """
  end

  # -------------------------------------------------------------------------

  def handle_event("filter", params, socket) do
    params =
      params
      |> Map.take(~w(q status sort_by charity))
      |> Map.reject(fn {_, v} -> v == "" end)

    socket = push_patch(socket, to: ~p"/raffles?#{params}")

    {:noreply, socket}
  end
end
