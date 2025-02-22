defmodule PhilomenaWeb.ProfileController do
  use PhilomenaWeb, :controller

  alias PhilomenaWeb.ImageLoader
  alias Philomena.Textile.Renderer
  alias Philomena.UserStatistics.UserStatistic
  alias Philomena.Users.User
  alias Philomena.Galleries.Gallery
  alias Philomena.Posts.Post
  alias Philomena.Comments.Comment
  alias Philomena.Interactions
  alias Philomena.Repo
  import Ecto.Query

  plug :load_and_authorize_resource, model: User, only: :show, id_field: "slug", preload: [
    awards: :badge, public_links: :tag, commission: [sheet_image: :tags, items: [example_image: :tags]]
  ]

  def show(conn, _params) do
    current_user = conn.assigns.current_user
    user = conn.assigns.user

    {:ok, {recent_uploads, _tags}} =
      ImageLoader.search_string(
        conn,
        "uploader_id:#{user.id}",
        pagination: %{page_number: 1, page_size: 6}
      )

    {:ok, {recent_faves, _tags}} =
      ImageLoader.search_string(
        conn,
        "faved_by_id:#{user.id}",
        pagination: %{page_number: 1, page_size: 6}
      )

    tags = tags(conn.assigns.user.public_links)
    recent_artwork = recent_artwork(conn, tags)

    recent_comments =
      Comment.search_records(
        %{
          query: %{
            bool: %{
              must: [
                %{term: %{user_id: user.id}},
                %{term: %{anonymous: false}},
                %{term: %{hidden_from_users: false}}
              ]
            }
          },
          sort: %{posted_at: :desc}
        },
        %{page_size: 3},
        Comment |> preload(user: [awards: :badge], image: :tags)
      )
      |> Enum.filter(&Canada.Can.can?(current_user, :show, &1.image))

    recent_comments =
      recent_comments
      |> Renderer.render_collection(conn)
      |> Enum.zip(recent_comments)

    recent_posts =
      Post.search_records(
        %{
          query: %{
            bool: %{
              must: [
                %{term: %{user_id: user.id}},
                %{term: %{anonymous: false}},
                %{term: %{deleted: false}},
                %{term: %{access_level: "normal"}}
              ]
            }
          },
          sort: %{created_at: :desc}
        },
        %{page_size: 6},
        Post |> preload(user: [awards: :badge], topic: :forum)
      )
      |> Enum.filter(&Canada.Can.can?(current_user, :show, &1.topic))

    about_me =
      Renderer.render_one(%{body: user.description || ""}, conn)

    commission_information =
      commission_info(user.commission, conn)

    recent_galleries =
      Gallery
      |> where(creator_id: ^user.id)
      |> preload([:creator, thumbnail: :tags])
      |> limit(5)
      |> Repo.all()

    statistics = calculate_statistics(user)

    interactions =
      Interactions.user_interactions([recent_uploads, recent_faves], current_user)

    render(
      conn,
      "show.html",
      user: user,
      interactions: interactions,
      commission_information: commission_information,
      recent_artwork: recent_artwork,
      recent_uploads: recent_uploads,
      recent_faves: recent_faves,
      recent_comments: recent_comments,
      recent_posts: recent_posts,
      recent_galleries: recent_galleries,
      statistics: statistics,
      about_me: about_me,
      tags: tags,
      layout_class: "layout--medium"
    )
  end

  defp calculate_statistics(user) do
    now =
      DateTime.utc_now()
      |> DateTime.to_unix(:second)
      |> div(86400)

    last_90 =
      UserStatistic
      |> where(user_id: ^user.id)
      |> where([us], us.day > ^(now - 89))
      |> Repo.all()
      |> Map.new(&{now - &1.day, &1})

    %{
      uploads: individual_stat(last_90, :uploads),
      images_favourited: individual_stat(last_90, :images_favourited),
      comments_posted: individual_stat(last_90, :comments_posted),
      votes_cast: individual_stat(last_90, :votes_cast),
      metadata_updates: individual_stat(last_90, :metadata_updates),
      forum_posts: individual_stat(last_90, :forum_posts)
    }
  end

  defp individual_stat(mapping, stat_name) do
    Enum.map((89..0), &map_fetch(mapping[&1], stat_name) || 0)
  end

  defp map_fetch(nil, _field_name), do: nil
  defp map_fetch(map, field_name), do: Map.get(map, field_name)

  defp commission_info(%{information: info}, conn) when info not in [nil, ""],
    do: Renderer.render_one(%{body: info}, conn)
  defp commission_info(_commission, _conn), do: ""

  defp tags([]), do: []
  defp tags(links), do: Enum.map(links, & &1.tag) |> Enum.reject(&is_nil/1)

  defp recent_artwork(_conn, []), do: []
  defp recent_artwork(conn, tags) do
    {images, _tags} =
      ImageLoader.query(
        conn,
        %{terms: %{tag_ids: Enum.map(tags, & &1.id)}},
        pagination: %{page_number: 1, page_size: 6}
      )

    images
  end
end
