defmodule RaffleyWeb.RafflesLive.Show do
  use RaffleyWeb, :live_view

  alias Raffley.Raffles
  alias Raffley.Tickets
  alias Raffley.Tickets.Ticket
  alias RaffleyWeb.Presence

  import RaffleyWeb.CustomComponents

  on_mount {RaffleyWeb.UserAuth, :mount_current_scope}

  def mount(_, _session, socket) do
    socket =
      if socket.assigns[:current_scope] do
        changeset = Tickets.change_ticket(socket.assigns.current_scope, %Ticket{})
        assign(socket, :form, to_form(changeset))
      else
        assign(socket, :form, nil)
      end

    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    current_scope = socket.assigns.current_scope
    current_user = current_scope && current_scope.user

    if connected?(socket) do
      Raffles.subscribe(id)

      if current_user do
        Presence.track_user(id, current_user)

        Presence.subscribe(id)
      end
    end

    presence = Presence.list_users(id)

    raffle = Raffles.get_raffle!(id)

    tickets = Raffles.list_tickets(raffle)

    socket =
      socket
      |> assign(:raffle, raffle)
      |> assign(:current_user, current_user)
      |> stream(:tickets, tickets)
      |> stream(:presences, presence)
      |> assign(:ticket_count, Enum.count(tickets))
      |> assign(:ticket_sum, Enum.reduce(tickets, 0, &(&1.price + &2)))
      |> assign(:page_title, raffle.prize)
      |> assign_async(:featured_raffles, fn ->
        {:ok, %{featured_raffles: Raffles.featured_raffles(raffle)}}
      end)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.banner :if={@raffle.winning_ticket}>
        <.icon name="hero-sparkles-solid" /> Ticket #{@raffle.winning_ticket.id} wins
        <:details>
          {@raffle.winning_ticket.comment}
        </:details>
      </.banner>

      <div class="raffle-show">
        <div class="raffle">
          <img src={@raffle.image_path} alt="" />

          <section>
            <.badge status={@raffle.status} />
            <header class="flex flex-col gap-5 lg:flex-row">
              <div>
                <h2 class="text-xl">{@raffle.prize}</h2>
                <h3 class="text-base">{@raffle.charity.name}</h3>
              </div>
              <div class="price text-lg font-bold">
                $ {@raffle.ticket_price} / Ticket
              </div>
            </header>

            <div class="totals text-sm">
              {@ticket_count} Ticket Sold &bull; ${@ticket_sum} raised
            </div>

            <div class="description text-base">
              {@raffle.description}
            </div>
          </section>
        </div>

        <div class="activity flex flex-col gap-5 lg:flex-row lg:justify-between">
          <div class="left">
            <div :if={@raffle.status == :open}>
              <%= if @current_scope && @form do %>
                <.form
                  class="relative gap-5 flex flex-row items-center"
                  for={@form}
                  phx-change="validate"
                  phx-submit="save"
                >
                  <.input
                    class="border p-2 rounded-xl"
                    field={@form[:comment]}
                    placeholder="Comment"
                    autofocus
                  />
                  <.button class="button">
                    Get a ticket
                  </.button>
                </.form>
              <% else %>
                <.link href={~p"/users/log-in"} class="button">Login to get ticket</.link>
              <% end %>
            </div>

            <div id="tickets" phx-update="stream">
              <.ticket
                :for={{dom_id, ticket} <- @streams.tickets}
                ticket={ticket}
                id={dom_id}
              />
            </div>
          </div>
          <div class="right">
            <.featured_raffles raffles={@featured_raffles} />

            <.raffle_watchers :if={@current_user} presences={@streams.presences} />
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def raffle_watchers(assigns) do
    ~H"""
    <section>
      <h4>Who here ?</h4>
      <ul class="presences" id="raffle-watchers" phx-update="stream">
        <li :for={{dom_id, %{id: username, metas: metas}} <- @presences} id={dom_id}>
          <.icon name="hero-user-circle-solid" class="w-5 h-5" />
          {username} ({length(metas)})
        </li>
      </ul>
    </section>
    """
  end

  def featured_raffles(assigns) do
    ~H"""
    <section>
      <h4>Featured Raffles</h4>

      <.async_result :let={result} assign={@raffles}>
        <:loading>
          <div class="loading">
            <div class="spinner"></div>
          </div>
        </:loading>

        <:failed :let={{:error, reason}}>
          <div class="failed">
            Oops: {reason}
          </div>
        </:failed>

        <ul class="raffles">
          <li :for={raffle <- result}>
            <.link navigate={~p"/raffles/#{raffle.id}"}>
              <img src={raffle.image_path} alt="" />
              {raffle.prize}
            </.link>
          </li>
        </ul>
      </.async_result>
    </section>
    """
  end

  attr :id, :string, required: true
  attr :ticket, Ticket, required: true

  def ticket(assigns) do
    ~H"""
    <div class="ticket" id={@id}>
      <span class="timeline"></span>
      <section>
        <div class="price-paid">
          ${@ticket.price}
        </div>

        <div>
          <span class="username">
            {@ticket.user.username}
          </span>
          Bough Ticket
          <blockquote>
            {@ticket.comment}
          </blockquote>
        </div>
      </section>
    </div>
    """
  end

  def handle_event("validate", %{"ticket" => ticket_params}, socket) do
    changeset = Tickets.change_ticket(socket.assigns.current_scope, %Ticket{}, ticket_params)

    socket = assign(socket, :form, to_form(changeset, action: :validate))

    {:noreply, socket}
  end

  def handle_event("save", %{"ticket" => ticket_params}, socket) do
    %{raffle: raffle, current_scope: scope} = socket.assigns

    user = scope.user

    case Tickets.create_ticket(scope, raffle, user, ticket_params) do
      {:ok, _ticket} ->
        changeset = Tickets.change_ticket(scope, %Ticket{})

        socket =
          socket
          |> assign(:form, to_form(changeset))

        {:noreply, socket}

      {:error, changeset} ->
        socket = assign(socket, :form, to_form(changeset))

        {:noreply, socket}
    end
  end

  def handle_info({:ticket_created, ticket}, socket) do
    socket =
      socket
      |> stream_insert(:tickets, ticket, at: 0)
      |> update(:ticket_count, &(&1 + 1))
      |> update(:ticket_sum, &(&1 + ticket.price))

    {:noreply, socket}
  end

  def handle_info({:raffle_update, raffle}, socket) do
    socket = assign(socket, :raffle, raffle)

    {:noreply, socket}
  end

  def handle_info({:user_joined, presence}, socket) do
    {:noreply, stream_insert(socket, :presences, presence)}
  end

  def handle_info({:user_left, presence}, socket) do
    if presence.metas == [] do
      {:noreply, stream_delete(socket, :presences, presence)}
    else
      {:noreply, stream_insert(socket, :presences, presence)}
    end
  end
end
