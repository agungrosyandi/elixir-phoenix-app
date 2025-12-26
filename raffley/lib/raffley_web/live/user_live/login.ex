defmodule RaffleyWeb.UserLive.Login do
  use RaffleyWeb, :live_view

  alias Raffley.Accounts

  # RENDER -------------------------------------------------------------------------------------------

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="relative flex w-full flex-col gap-3 lg:min-h-[70vh] lg:flex-row">
        
    <!-- image ----------------->

        <div class="w-[100%]">
          <img
            class="relative h-full w-full object-cover rounded-xl"
            src="/images/image-1.jpg"
            alt="My Image"
          />
        </div>
        
    <!-- right ----------------->

        <div class="mx-auto w-full h-full space-y-6 rounded-xl p-8 shadow-md">
          <.header>
            <div class="flex flex-row items-center py-5">
              <div class="h-[0.1rem] w-full bg-black"></div>
              <p class="px-5 text-3xl">Login</p>
              <div class="h-[0.1rem] w-full bg-black"></div>
            </div>

            <:subtitle>
              <%= if @current_scope do %>
                <p class="text-base">
                  You need to reauthenticate to perform sensitive actions on your account.
                </p>
              <% else %>
                <p class="text-base w-full text-center">
                  Don't have an account ? <.link
                    navigate={~p"/users/register"}
                    class="font-semibold"
                    phx-no-format
                  >Sign up</.link> for an account now.
                </p>
              <% end %>
            </:subtitle>
          </.header>

          <div :if={local_mail_adapter?()} class="text-base w-full text-center">
            <p>You are running the local mail adapter.</p>
            <p>
              To see sent emails, visit <.link href="/dev/mailbox" class="underline">the mailbox page</.link>.
            </p>
          </div>

          <.form
            :let={f}
            for={@form}
            id="login_form_magic"
            action={~p"/users/log-in"}
            phx-submit="submit_magic"
          >
            <.input
              class="input w-full"
              readonly={!!@current_scope}
              field={f[:email]}
              type="email"
              autocomplete="email"
              required
              placeholder="email"
              phx-mounted={JS.focus()}
            />
            <.button class="btn btn-neutral w-full mt-5">
              Log in with email <span aria-hidden="true">→</span>
            </.button>

            <div class="flex flex-row items-center py-5">
              <div class="h-[0.1rem] w-full bg-black"></div>
              <div class="px-5 text-xl">or</div>
              <div class="h-[0.1rem] w-full bg-black"></div>
            </div>
          </.form>

          <.form
            :let={f}
            for={@form}
            id="login_form_password"
            action={~p"/users/log-in"}
            phx-submit="submit_password"
            phx-trigger-action={@trigger_submit}
          >
            <.input
              class="input w-full"
              readonly={!!@current_scope}
              field={f[:email]}
              type="email"
              label="Email"
              autocomplete="email"
              required
            />
            <.input
              class="input w-full"
              field={@form[:password]}
              type="password"
              label="Password"
              autocomplete="current-password"
            />

            <.button class="btn btn-neutral w-full mt-5">
              Login
            </.button>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # MOUNT -------------------------------------------------------------------------------------------

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  # HANDLE EVENT -------------------------------------------------------------------------------------------

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:raffley, Raffley.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
