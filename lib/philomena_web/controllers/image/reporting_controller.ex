defmodule PhilomenaWeb.Image.ReportingController do
  use PhilomenaWeb, :controller

  alias Philomena.Images.Image
  alias Philomena.DuplicateReports.DuplicateReport
  alias Philomena.DuplicateReports
  alias Philomena.Repo
  import Ecto.Query

  plug :load_and_authorize_resource, model: Image, id_name: "image_id", persisted: true, preload: [:tags]

  def show(conn, _params) do
    image = conn.assigns.image

    dupe_reports =
      DuplicateReport
      |> preload([:user, image: [:user, :tags], duplicate_of_image: [:user, :tags]])
      |> where([d], d.image_id == ^image.id or d.duplicate_of_image_id == ^image.id)
      |> Repo.all()

    changeset =
      %DuplicateReport{}
      |> DuplicateReports.change_duplicate_report()

    render(conn, "show.html", layout: false, image: image, dupe_reports: dupe_reports, changeset: changeset)
  end
end