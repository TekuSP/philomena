defmodule Philomena.Bans do
  @moduledoc """
  The Bans context.
  """

  import Ecto.Query, warn: false
  alias Philomena.Repo

  alias Philomena.Bans.Fingerprint

  @doc """
  Returns the list of fingerprint_bans.

  ## Examples

      iex> list_fingerprint_bans()
      [%Fingerprint{}, ...]

  """
  def list_fingerprint_bans do
    Repo.all(Fingerprint)
  end

  @doc """
  Gets a single fingerprint.

  Raises `Ecto.NoResultsError` if the Fingerprint does not exist.

  ## Examples

      iex> get_fingerprint!(123)
      %Fingerprint{}

      iex> get_fingerprint!(456)
      ** (Ecto.NoResultsError)

  """
  def get_fingerprint!(id), do: Repo.get!(Fingerprint, id)

  @doc """
  Creates a fingerprint.

  ## Examples

      iex> create_fingerprint(%{field: value})
      {:ok, %Fingerprint{}}

      iex> create_fingerprint(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_fingerprint(attrs \\ %{}) do
    %Fingerprint{}
    |> Fingerprint.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a fingerprint.

  ## Examples

      iex> update_fingerprint(fingerprint, %{field: new_value})
      {:ok, %Fingerprint{}}

      iex> update_fingerprint(fingerprint, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_fingerprint(%Fingerprint{} = fingerprint, attrs) do
    fingerprint
    |> Fingerprint.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Fingerprint.

  ## Examples

      iex> delete_fingerprint(fingerprint)
      {:ok, %Fingerprint{}}

      iex> delete_fingerprint(fingerprint)
      {:error, %Ecto.Changeset{}}

  """
  def delete_fingerprint(%Fingerprint{} = fingerprint) do
    Repo.delete(fingerprint)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking fingerprint changes.

  ## Examples

      iex> change_fingerprint(fingerprint)
      %Ecto.Changeset{source: %Fingerprint{}}

  """
  def change_fingerprint(%Fingerprint{} = fingerprint) do
    Fingerprint.changeset(fingerprint, %{})
  end

  alias Philomena.Bans.Subnet

  @doc """
  Returns the list of subnet_bans.

  ## Examples

      iex> list_subnet_bans()
      [%Subnet{}, ...]

  """
  def list_subnet_bans do
    Repo.all(Subnet)
  end

  @doc """
  Gets a single subnet.

  Raises `Ecto.NoResultsError` if the Subnet does not exist.

  ## Examples

      iex> get_subnet!(123)
      %Subnet{}

      iex> get_subnet!(456)
      ** (Ecto.NoResultsError)

  """
  def get_subnet!(id), do: Repo.get!(Subnet, id)

  @doc """
  Creates a subnet.

  ## Examples

      iex> create_subnet(%{field: value})
      {:ok, %Subnet{}}

      iex> create_subnet(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_subnet(attrs \\ %{}) do
    %Subnet{}
    |> Subnet.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a subnet.

  ## Examples

      iex> update_subnet(subnet, %{field: new_value})
      {:ok, %Subnet{}}

      iex> update_subnet(subnet, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_subnet(%Subnet{} = subnet, attrs) do
    subnet
    |> Subnet.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Subnet.

  ## Examples

      iex> delete_subnet(subnet)
      {:ok, %Subnet{}}

      iex> delete_subnet(subnet)
      {:error, %Ecto.Changeset{}}

  """
  def delete_subnet(%Subnet{} = subnet) do
    Repo.delete(subnet)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking subnet changes.

  ## Examples

      iex> change_subnet(subnet)
      %Ecto.Changeset{source: %Subnet{}}

  """
  def change_subnet(%Subnet{} = subnet) do
    Subnet.changeset(subnet, %{})
  end

  alias Philomena.Bans.User

  @doc """
  Returns the list of user_bans.

  ## Examples

      iex> list_user_bans()
      [%User{}, ...]

  """
  def list_user_bans do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  @doc """
  Returns the first ban, if any, that matches the specified request
  attributes.
  """
  def exists_for?(user, ip, fingerprint) do
    now = DateTime.utc_now()
    queries =
      subnet_query(ip, now) ++
      fingerprint_query(fingerprint, now) ++
      user_query(user, now)

    union_all_queries(queries)
    |> limit(1)
    |> Repo.one()
  end

  defp fingerprint_query(nil, _now), do: []
  defp fingerprint_query(fingerprint, now) do
    [
      Fingerprint
      |> select([:id, :reason, :valid_until])
      |> where([f], f.enabled and f.valid_until > ^now)
      |> where([f], f.fingerprint == ^fingerprint)
    ]
  end

  defp subnet_query(nil, _now), do: []
  defp subnet_query(ip, now) do
    {:ok, inet} = EctoNetwork.INET.cast(ip)

    [
      Subnet
      |> select([:id, :reason, :valid_until])
      |> where([s], s.enabled and s.valid_until > ^now)
      |> where(fragment("specification >>= ?", ^inet))
    ]
  end

  defp user_query(nil, _now), do: []
  defp user_query(user, now) do
    [
      User
      |> select([:id, :reason, :valid_until])
      |> where([u], u.enabled and u.valid_until > ^now)
      |> where([u], u.user_id == ^user.id)
    ]
  end

  defp union_all_queries([query]),
    do: query
  defp union_all_queries([query | rest]),
    do: query |> union_all(^union_all_queries(rest))
end
