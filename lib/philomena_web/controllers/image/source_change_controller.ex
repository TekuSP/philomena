defmodule PhilomenaWeb.Image.SourceChangeController do
  use PhilomenaWeb, :controller

  alias Philomena.Images.Image
  alias Philomena.SourceChanges.SourceChange
  alias Philomena.Repo
  import Ecto.Query

  plug PhilomenaWeb.CanaryMapPlug, index: :show
  plug :load_and_authorize_resource, model: Image, id_name: "image_id", persisted: true

  def index(conn, _params) do
    image = conn.assigns.image

    source_changes =
      SourceChange
      |> where(image_id: ^image.id)
      |> preload([:user, image: [:user, :tags]])
      |> order_by(desc: :created_at)
      |> Repo.paginate(conn.assigns.scrivener)
    
    render(conn, "index.html", image: image, source_changes: source_changes)
  end
end