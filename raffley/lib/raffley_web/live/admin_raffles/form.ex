defmodule RaffleyWeb.AdminRafflesLive.Form do
  use RaffleyWeb, :live_view

  alias Raffley.Admin
  alias Raffley.Raffles.Raffle
  alias Raffley.Charities

  # MOUNT ----------------------------------------------------

  def mount(params, _, socket) do
    socket =
      socket
      |> assign(:charity_options, Charities.charity_names_and_ids())
      |> apply_action(socket.assigns.live_action, params)

    {:ok, socket}
  end

  # NEW ----------------------------------------------------

  defp apply_action(socket, :new, _) do
    raffle = %Raffle{}

    changeset = Admin.change_raffle(raffle)

    socket
    |> assign(:page_title, "New Raffle")
    |> assign(:form, to_form(changeset))
    |> assign(:raffle, raffle)
  end

  # EDIT ----------------------------------------------------

  defp apply_action(socket, :edit, %{"id" => id}) do
    raffle = Admin.get_raffle!(id)

    changeset = Admin.change_raffle(raffle)

    socket
    |> assign(:page_title, "Edit Raffle")
    |> assign(:form, to_form(changeset))
    |> assign(:raffle, raffle)
  end

  # RENDER TEMPLATE -------------------------------------------------------

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex justify-center py-10">
        <div class="w-full rounded-xl border border-zinc-200 bg-white shadow-sm">
          
    <!-- header -->

          <div class="border-b border-zinc-200 px-6 py-4">
            <.header>
              <h2 class="text-lg font-semibold text-zinc-900">{@page_title}</h2>
            </.header>
          </div>
          
    <!-- form -->

          <div class="relative p-6">
            <.form
              for={@form}
              phx-submit="save"
              phx-change="validate"
              class="space-y-5 flex flex-col gap-3"
            >
              
    <!-- price -->

              <.input
                field={@form[:prize]}
                label="Prize"
                class="w-full border p-3 border-zinc-200 bg-white shadow-sm"
              />
              
    <!-- description -->

              <.input
                field={@form[:description]}
                type="textarea"
                label="Description"
                phx-debounce="blur"
                class="w-full p-3 min-h-[100px] border border-zinc-200 bg-white shadow-sm"
              />
              
    <!-- number -->

              <.input
                field={@form[:ticket_price]}
                type="number"
                label="Ticket price"
                class="w-full p-3 border border-zinc-200 bg-white shadow-sm"
              />
              
    <!-- status -->

              <.input
                field={@form[:status]}
                type="select"
                label="Status"
                prompt="Choose a status"
                options={[:upcoming, :open, :closed]}
                class="w-full p-3 border border-zinc-200 bg-white shadow-sm"
              />
              
    <!-- charity select -->

              <.input
                field={@form[:charity_id]}
                type="select"
                label="Charity"
                prompt="Choose a charity"
                options={@charity_options}
                class="w-full p-3 border border-zinc-200 bg-white shadow-sm"
              />
              
    <!-- upload image -->

              <.input
                field={@form[:image_path]}
                label="Image Path"
                class="w-full p-3 border border-zinc-200 bg-white shadow-sm"
              />
              
    <!-- submit button form -->

              <div class="flex justify-start pt-4">
                <.button
                  phx-disable-with="Saving...."
                  class="rounded-md cursor-pointer bg-zinc-900 px-6 py-2 text-sm font-medium text-white hover:bg-zinc-800 focus:outline-none focus:ring-2 focus:ring-zinc-400"
                >
                  Save Raffles
                </.button>
              </div>
            </.form>
            
    <!-- back to main menu -->

            <div class="mt-5">
              <.link class="text-sm" navigate={~p"/admin/raffles"}>
                ⮜ Back to Admin
              </.link>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # HANDLE EVENT VALIDATE --------------------------------------------

  def handle_event("validate", %{"raffle" => raffle_params}, socket) do
    changeset = Admin.change_raffle(socket.assigns.raffle, raffle_params)
    socket = assign(socket, :form, to_form(changeset, action: :validate))

    {:noreply, socket}
  end

  # HANDLE EVENT SUBMIT & SAVE  --------------------------------------------

  def handle_event("save", %{"raffle" => raffle_params}, socket) do
    save_raffle(socket, socket.assigns.live_action, raffle_params)
  end

  # CREATE CONTENT  --------------------------------------------

  defp save_raffle(socket, :new, raffle_params) do
    case Admin.create_raffle(raffle_params) do
      {:ok, _raffle} ->
        socket =
          socket
          |> put_flash(:success, "Create successful.")
          |> push_navigate(to: ~p"/admin/raffles")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket = assign(socket, :form, to_form(changeset))

        {:noreply, socket}
    end
  end

  # EDIT CONTENT --------------------------------------------

  defp save_raffle(socket, :edit, raffle_params) do
    case Admin.update_raffle(socket.assigns.raffle, raffle_params) do
      {:ok, _raffle} ->
        socket =
          socket
          |> put_flash(:success, "Update successful.")
          |> push_navigate(to: ~p"/admin/raffles")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket = assign(socket, :form, to_form(changeset))

        {:noreply, socket}
    end
  end
end
