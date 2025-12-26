defmodule RaffleyWeb.EstimatorLive do
  use RaffleyWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Process.send_after(self(), :tick, 2000)
    end

    socket = assign(socket, tickets: 0, price: 3, page_title: "Estimator")

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="estimator">
        <h1>Raffley Estimator</h1>

        <section>
          <button phx-click="add" phx-value-quantity="5">+</button>

          <div>
            {@tickets}
          </div>
          *
          <div>
            {@price}
          </div>
          =
          <div>
            ${@tickets * @price}
          </div>
        </section>

        <form phx-submit="set-price">
          <label for="">Ticket price: </label>
          <input type="text" name="price" value={@price} />
        </form>
      </div>
    </Layouts.app>
    """
  end

  # EVENTS

  def handle_event("add", %{"quantity" => quantity}, socket) do
    socket = update(socket, :tickets, &(&1 + String.to_integer(quantity)))

    {:noreply, socket}
  end

  def handle_event("set-price", %{"price" => price}, socket) do
    socket = assign(socket, :price, String.to_integer(price))

    {:noreply, socket}
  end

  # INFO

  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, 2000)

    {:noreply, update(socket, :tickets, &(&1 + 10))}
  end
end
