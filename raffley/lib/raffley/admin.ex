defmodule Raffley.Admin do
  alias Raffley.Raffles
  alias Raffley.Raffles.Raffle
  alias Raffley.Repo

  import Ecto.Query

  # LIST ALL RAFFLE

  def list_raffles do
    Raffle
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  # CREATE RAFFLE

  def create_raffle(attrs \\ %{}) do
    %Raffle{}
    |> Raffle.changeset(attrs)
    |> Repo.insert()
  end

  # VALIDATE CHANGESET

  def change_raffle(%Raffle{} = raffle, attrs \\ %{}) do
    Raffle.changeset(raffle, attrs)
  end

  # GET RAFFLE BY ID

  def get_raffle!(id) do
    Repo.get!(Raffle, id)
  end

  # UPDATE RAFFLE

  def update_raffle(%Raffle{} = raffle, attrs) do
    raffle
    |> Raffle.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, raffle} ->
        raffle = Repo.preload(raffle, [:charity, :winning_ticket])

        Raffles.broadcast(raffle.id, {:raffle_update, raffle})
        {:ok, raffle}

      {:error, _} = error ->
        error
    end
  end

  # DRAW WINNER

  def draw_winner(%Raffle{status: :closed} = raffle) do
    raffle = Repo.preload(raffle, :tickets)

    case raffle.tickets do
      [] ->
        {:error, "No Ticket to draw!"}

      tickets ->
        winner = Enum.random(tickets)

        {:ok, _} = update_raffle(raffle, %{winning_ticket_id: winner.id})
    end
  end

  def draw_winner(%Raffle{}) do
    {:error, "Raffle must be closed to draw winner"}
  end

  # DELETE RAFFLE

  def delete_raffle(%Raffle{} = raffle) do
    Repo.delete(raffle)
  end
end
