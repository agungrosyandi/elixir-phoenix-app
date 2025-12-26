defmodule RaffleyWeb.UserLive.Confirmation do
  use RaffleyWeb, :live_view

  alias Raffley.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto w-[50%] space-y-6 rounded-xl bg-white p-8 shadow-md">
        <div class="relative flex flex-col items-center gap-5">
          <.header>
            <div class="text-center">
              <h1 class="text-2xl font-bold">Welcome {@user.username}</h1>
              <h1 class="text-xs mt-2">{@user.email}</h1>
            </div>
          </.header>

          <div class="h-[0.1rem] w-full bg-black mb-5"></div>

          <.form
            :if={!@user.confirmed_at}
            for={@form}
            id="confirmation_form"
            phx-mounted={JS.focus_first()}
            phx-submit="submit"
            action={~p"/users/log-in?_action=confirmed"}
            phx-trigger-action={@trigger_submit}
          >
            <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
            <.button
              name={@form[:remember_me].name}
              value="true"
              phx-disable-with="Confirming..."
              class="button"
            >
              Confirm and stay logged in
            </.button>
            <.button phx-disable-with="Confirming..." class="button">
              Confirm and log in only this time
            </.button>
          </.form>

          <.form
            :if={@user.confirmed_at}
            for={@form}
            id="login_form"
            phx-submit="submit"
            phx-mounted={JS.focus_first()}
            action={~p"/users/log-in"}
            phx-trigger-action={@trigger_submit}
          >
            <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
            <%= if @current_scope do %>
              <.button phx-disable-with="Logging in..." class="btn btn-primary w-full">
                Log in
              </.button>
            <% else %>
              <div class="flex gap-5">
                <.button
                  name={@form[:remember_me].name}
                  value="true"
                  phx-disable-with="Logging in..."
                  class="button cursor-pointer"
                >
                  Keep me logged in on this device
                </.button>
                <.button phx-disable-with="Logging in..." class="button cursor-pointer">
                  Log me in only this time
                </.button>
              </div>
            <% end %>
          </.form>

          <p :if={!@user.confirmed_at} class="">
            Tip: If you prefer passwords, you can enable them in the user settings.
          </p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    if user = Accounts.get_user_by_magic_link_token(token) do
      form = to_form(%{"token" => token}, as: "user")

      {:ok, assign(socket, user: user, form: form, trigger_submit: false),
       temporary_assigns: [form: nil]}
    else
      {:ok,
       socket
       |> put_flash(:error, "Magic link is invalid or it has expired.")
       |> push_navigate(to: ~p"/users/log-in")}
    end
  end

  @impl true
  def handle_event("submit", %{"user" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "user"), trigger_submit: true)}
  end
end
