defmodule Raffley.Tickets do
  @moduledoc """
  The Tickets context.
  """

  import Ecto.Query, warn: false
  alias Raffley.Raffles
  alias Raffley.Repo

  alias Raffley.Tickets.Ticket
  alias Raffley.Accounts.Scope

  alias Raffley.Raffles.Raffle
  alias Raffley.Accounts.User
  alias Raffley.Raffles

  @doc """
  Subscribes to scoped notifications about any ticket changes.

  The broadcasted messages match the pattern:

    * {:created, %Ticket{}}
    * {:updated, %Ticket{}}
    * {:deleted, %Ticket{}}

  """
  def subscribe_tickets(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Raffley.PubSub, "user:#{key}:tickets")
  end

  defp broadcast_ticket(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Raffley.PubSub, "user:#{key}:tickets", message)
  end

  @doc """
  Returns the list of tickets.

  ## Examples

      iex> list_tickets(scope)
      [%Ticket{}, ...]

  """
  def list_tickets(%Scope{} = scope) do
    Repo.all_by(Ticket, user_id: scope.user.id)
  end

  @doc """
  Gets a single ticket.

  Raises `Ecto.NoResultsError` if the Ticket does not exist.

  ## Examples

      iex> get_ticket!(scope, 123)
      %Ticket{}

      iex> get_ticket!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_ticket!(%Scope{} = scope, id) do
    Repo.get_by!(Ticket, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a ticket.

  ## Examples

      iex> create_ticket(scope, %{field: value})
      {:ok, %Ticket{}}

      iex> create_ticket(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  # def create_ticket(%Scope{} = scope, %Raffle{} = raffle, %User{} = user, attrs \\ %{}) do
  #   with {:ok, ticket = %Ticket{}} <-
  #          %Ticket{raffle: raffle, user: user, price: raffle.ticket_price}
  #          |> Ticket.changeset(attrs, scope)
  #          |> Repo.insert() do
  #     broadcast_ticket(scope, {:created, ticket})
  #     {:ok, ticket}
  #   end
  # end

  def create_ticket(%Scope{} = scope, %Raffle{} = raffle, %User{} = user, attrs \\ %{}) do
    %Ticket{raffle: raffle, user: user, price: raffle.ticket_price}
    |> Ticket.changeset(attrs, scope)
    |> Repo.insert()
    |> case do
      {:ok, ticket} ->
        Raffles.broadcast(raffle.id, {:ticket_created, ticket})
        {:ok, ticket}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Updates a ticket.

  ## Examples

      iex> update_ticket(scope, ticket, %{field: new_value})
      {:ok, %Ticket{}}

      iex> update_ticket(scope, ticket, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ticket(%Scope{} = scope, %Ticket{} = ticket, attrs) do
    true = ticket.user_id == scope.user.id

    with {:ok, ticket = %Ticket{}} <-
           ticket
           |> Ticket.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_ticket(scope, {:updated, ticket})
      {:ok, ticket}
    end
  end

  @doc """
  Deletes a ticket.

  ## Examples

      iex> delete_ticket(scope, ticket)
      {:ok, %Ticket{}}

      iex> delete_ticket(scope, ticket)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ticket(%Scope{} = scope, %Ticket{} = ticket) do
    true = ticket.user_id == scope.user.id

    with {:ok, ticket = %Ticket{}} <-
           Repo.delete(ticket) do
      broadcast_ticket(scope, {:deleted, ticket})
      {:ok, ticket}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ticket changes.

  ## Examples

      iex> change_ticket(scope, ticket)
      %Ecto.Changeset{data: %Ticket{}}

  """

  def change_ticket(%Scope{} = scope, %Ticket{} = ticket, attrs \\ %{}) do
    # true = ticket.user_id == scope.user.id

    if ticket.user_id, do: true = ticket.user_id == scope.user.id

    Ticket.changeset(ticket, attrs, scope)
  end
end
