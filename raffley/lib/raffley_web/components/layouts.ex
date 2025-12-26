defmodule RaffleyWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use RaffleyWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="relative w-[80%] pb-5 mx-auto">
      <header class="relative min-h-[5vh] mb-5">
        <nav class="flex h-full w-full flex-row items-center justify-between">
          <.link navigate={~p"/"}><img src={~p"/images/raffley-logo.svg"} width="150" /></.link>
          
    <!-- navbar desktop -->

          <div class="hidden lg:block">
            <ul class="flex flex-row gap-5 text-base">
              <.link class="flex items-center gap-2" navigate={~p"/raffles"}>
                <.icon name="hero-chevron-down" />
                <p class="text-black text-base">Raffle</p>
              </.link>
              <.link class="flex items-center gap-2" navigate={~p"/admin/raffles"}>
                <.icon name="hero-chevron-down" />
                <p class="text-black text-base">Admin</p>
              </.link>
              <.link class="flex items-center gap-2" navigate={~p"/charities"}>
                <.icon name="hero-chevron-down" />
                <p class="text-black text-base">Charity</p>
              </.link>
            </ul>
          </div>
          
    <!-- navbar mobile tab -->

          <div class="navbar-start lg:hidden">
            <div class="dropdown w-full flex justify-end">
              <div tabindex="0" role="button" class="btn btn-ghost btn-circle">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M4 6h16M4 12h16M4 18h7"
                  />
                </svg>
              </div>
              <ul
                tabindex="-1"
                class="menu menu-sm dropdown-content bg-base-100 rounded-box z-1 mt-10 w-52 p-5 shadow"
              >
                <.link navigate={~p"/raffles"}>
                  <p class="text-black py-3 border-b-2">Raffle</p>
                </.link>
                <.link class="text-black py-3 border-b-2" navigate={~p"/estimator"}>
                  <p>Estimator</p>
                </.link>
                <.link class="text-black py-3 border-b-2" navigate={~p"/admin/raffles"}>
                  <p>Admin</p>
                </.link>
                <.link class="text-black py-3 border-b-2" navigate={~p"/charities"}>
                  <p>Charity</p>
                </.link>
              </ul>
            </div>
          </div>
        </nav>
      </header>

      <.flash_group flash={@flash} />

      <main>
        {render_slot(@inner_block)}
      </main>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
      <.flash kind={:success} flash={@flash} />
      <.flash kind={:warning} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
