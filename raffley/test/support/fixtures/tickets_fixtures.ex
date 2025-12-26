defmodule Raffley.TicketsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Raffley.Tickets` context.
  """

  @doc """
  Generate a ticket.
  """
  def ticket_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        comment: "some comment",
        price: 42
      })

    {:ok, ticket} = Raffley.Tickets.create_ticket(scope, attrs)
    ticket
  end
end
