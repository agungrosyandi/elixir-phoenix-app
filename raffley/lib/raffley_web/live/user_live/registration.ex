defmodule RaffleyWeb.UserLive.Registration do
  use RaffleyWeb, :live_view

  alias Raffley.Accounts
  alias Raffley.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="relative flex w-full flex-col gap-3 lg:min-h-[70vh] lg:flex-row">
        
    <!-- image ----------------->

        <div class="w-[100%]">
          <img
            class="relative h-full w-full object-cover"
            src="/images/balloon-ride.jpg"
            alt="My Image"
          />
        </div>

        <div class="mx-auto w-full h-full space-y-6 rounded-xl bg-white p-8 shadow-md">
          <.header>
            <p class="px-5 text-3xl w-full text-center">Register for account</p>

            <:subtitle>
              <p class="text-sm w-full text-center mt-5">
                Already registered ?
                <.link navigate={~p"/users/log-in"} class="font-semibold text-brand hover:underline">
                  Log in
                </.link>
                to your account now.
              </p>
            </:subtitle>
          </.header>

          <div class="h-[0.1rem] w-full bg-black"></div>

          <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
            <.input
              class="w-full rounded-lg border border-gray-300 p-3 text-base focus:ring-2 focus:ring-blue-500 focus:outline-none"
              field={@form[:email]}
              type="email"
              label="Email"
              autocomplete="username"
              required
              phx-mounted={JS.focus()}
            />

            <.input
              class="w-full rounded-lg border border-gray-300 p-3 text-base focus:ring-2 focus:ring-blue-500 focus:outline-none"
              field={@form[:username]}
              label="Username"
              required
              phx-mounted={JS.focus()}
            />

            <%!-- <.input
            field={@form[:password]}
            type="password"
            label="password"
            autocomplete="new-password"
            phx-mounted={JS.focus()}
          /> --%>

            <.button phx-disable-with="Creating account..." class="button my-5 cursor-pointer w-full">
              Create an account
            </.button>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: RaffleyWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_email(%User{}, %{}, validate_unique: false)

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "An email was sent to #{user.email}, please access it to confirm your account."
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_email(%User{}, user_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
