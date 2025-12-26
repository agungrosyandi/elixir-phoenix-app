defmodule Raffley.Tickets.Ticket do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tickets" do
    field :price, :integer
    field :comment, :string

    belongs_to :raffle, Raffley.Raffles.Raffle
    belongs_to :user, Raffley.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(ticket, attrs, user_scope) do
    ticket
    |> cast(attrs, [:price, :comment])
    |> validate_required([:price])
    |> validate_length(:comment, max: 100)
    |> assoc_constraint(:raffle)
    |> assoc_constraint(:user)
    |> put_change(:user_id, user_scope.user.id)
  end
end
