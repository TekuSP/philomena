defimpl Canada.Can, for: [Atom, Philomena.Users.User] do
  alias Philomena.Users.User
  alias Philomena.Comments.Comment
  alias Philomena.Commissions.Commission
  alias Philomena.Conversations.Conversation
  alias Philomena.DuplicateReports.DuplicateReport
  alias Philomena.Images.Image
  alias Philomena.Forums.Forum
  alias Philomena.Topics.Topic
  alias Philomena.Posts.Post
  alias Philomena.Filters.Filter
  alias Philomena.Galleries.Gallery
  alias Philomena.DnpEntries.DnpEntry
  alias Philomena.UserLinks.UserLink
  alias Philomena.Tags.Tag

  # Admins can do anything
  def can?(%User{role: "admin"}, _action, _model), do: true

  #
  # Moderators can...
  #

  # View filters
  def can?(%User{role: "moderator"}, :show, %Filter{}), do: true

  # View images
  def can?(%User{role: "moderator"}, :show, %Image{}), do: true

  # View comments
  def can?(%User{role: "moderator"}, :show, %Comment{}), do: true

  # View forums
  def can?(%User{role: "moderator"}, :show, %Forum{access_level: level})
    when level in ["normal", "assistant", "staff"], do: true
  def can?(%User{role: "moderator"}, :show, %Topic{hidden_from_users: true}), do: true

  # View conversations
  def can?(%User{role: "moderator"}, :show, %Conversation{}), do: true

  # View IP addresses and fingerprints
  def can?(%User{role: "moderator"}, :show, :ip_address), do: true

  #
  # Assistants can...
  #


  # Image assistant actions
  def can?(%User{role: "assistant", role_map: %{"Image" => "moderator"}}, :show, %Image{}), do: true
  def can?(%User{role: "assistant", role_map: %{"Image" => "moderator"}}, :hide, %Image{}), do: true
  def can?(%User{role: "assistant", role_map: %{"Image" => "moderator"}}, :edit, %Image{}), do: true

  # Dupe assistant actions
  def can?(%User{role: "assistant", role_map: %{"DuplicateReport" => "moderator"}}, :edit, %DuplicateReport{}), do: true
  def can?(%User{role: "assistant", role_map: %{"DuplicateReport" => "moderator"}}, :show, %Image{}), do: true
  def can?(%User{role: "assistant", role_map: %{"DuplicateReport" => "moderator"}}, :edit, %Image{}), do: true
  def can?(%User{role: "assistant", role_map: %{"DuplicateReport" => "moderator"}}, :hide, %Comment{}), do: true

  # Comment assistant actions
  def can?(%User{role: "assistant", role_map: %{"Comment" => "moderator"}}, :show, %Comment{}), do: true
  def can?(%User{role: "assistant", role_map: %{"Comment" => "moderator"}}, :edit, %Comment{}), do: true
  def can?(%User{role: "assistant", role_map: %{"Comment" => "moderator"}}, :hide, %Comment{}), do: true

  # Topic assistant actions
  def can?(%User{role: "assistant", role_map: %{"Topic" => "moderator"}}, :show, %Topic{}), do: true
  def can?(%User{role: "assistant", role_map: %{"Topic" => "moderator"}}, :edit, %Topic{}), do: true
  def can?(%User{role: "assistant", role_map: %{"Topic" => "moderator"}}, :show, %Post{}), do: true
  def can?(%User{role: "assistant", role_map: %{"Topic" => "moderator"}}, :edit, %Post{}), do: true
  def can?(%User{role: "assistant", role_map: %{"Topic" => "moderator"}}, :hide, %Post{}), do: true

  # Tag assistant actions
  def can?(%User{role: "assistant", role_map: %{"Tag" => "moderator"}}, :edit, %Tag{}), do: true

  # User link assistant actions
  def can?(%User{role: "assistant", role_map: %{"UserLink" => "moderator"}}, :show, %UserLink{}), do: true
  def can?(%User{role: "assistant", role_map: %{"UserLink" => "moderator"}}, :edit, %UserLink{}), do: true

  # View forums
  def can?(%User{role: "assistant"}, :show, %Forum{access_level: level})
    when level in ["normal", "assistant"], do: true
  def can?(%User{role: "assistant"}, :show, %Topic{hidden_from_users: true}), do: true

  #
  # Users and anonymous users can...
  #

  # Edit their description and personal title
  def can?(%User{id: id}, :edit_description, %User{id: id}), do: true
  def can?(%User{id: id}, :edit_title, %User{id: id}), do: true

  # View conversations they are involved in
  def can?(%User{id: id}, :show, %Conversation{to_id: id}), do: true
  def can?(%User{id: id}, :show, %Conversation{from_id: id}), do: true

  # View filters they own and system filters
  def can?(_user, :show, %Filter{system: true}), do: true
  def can?(%User{id: id}, :show, %Filter{user_id: id}), do: true

  # Edit filters they own
  def can?(%User{id: id}, action, %Filter{user_id: id}) when action in [:edit, :update], do: true

  # View user links they've created
  def can?(%User{id: id}, :show, %UserLink{user_id: id}), do: true

  # Edit their commissions
  def can?(%User{id: id}, action, %Commission{user_id: id}) when action in [:edit, :update, :delete], do: true

  # View non-deleted images
  def can?(_user, action, Image)
      when action in [:new, :create, :index],
      do: true

  def can?(_user, action, %Image{hidden_from_users: false})
      when action in [:show, :index],
      do: true

  # Comment on images where that is allowed
  def can?(_user, :create_comment, %Image{hidden_from_users: false, commenting_allowed: true}), do: true

  # Edit comments on images
  def can?(%User{id: id}, :edit, %Comment{hidden_from_users: false, user_id: id} = comment) do
    # comment must have been made no later than 15 minutes ago
    time_ago = NaiveDateTime.utc_now() |> NaiveDateTime.add(-15 * 60)

    NaiveDateTime.diff(comment.created_at, time_ago) > 0
  end

  # Edit metadata on images where that is allowed
  def can?(_user, :edit_metadata, %Image{hidden_from_users: false, tag_editing_allowed: true}), do: true
  def can?(%User{id: id}, :edit_description, %Image{user_id: id, hidden_from_users: false, description_editing_allowed: true}), do: true

  # Vote on images they can see
  def can?(user, :vote, image), do: can?(user, :show, image)

  # View non-deleted comments
  def can?(_user, :show, %Comment{hidden_from_users: false}), do: true

  # View forums
  def can?(_user, :index, Forum), do: true
  def can?(_user, :show, %Forum{access_level: "normal"}), do: true
  def can?(_user, :show, %Topic{hidden_from_users: false}), do: true
  def can?(_user, :show, %Post{hidden_from_users: false}), do: true
  
  # Create and edit posts
  def can?(_user, :create_post, %Topic{locked_at: nil, hidden_from_users: false}), do: true
  def can?(%User{id: id}, :edit, %Post{hidden_from_users: false, user_id: id}), do: true

  # View profile pages
  def can?(_user, :show, %User{}), do: true

  # View and create DNP entries
  def can?(%User{}, action, DnpEntry) when action in [:new, :create, :index], do: true
  def can?(%User{id: id}, :show, %DnpEntry{requesting_user_id: id}), do: true
  def can?(%User{id: id}, :show_reason, %DnpEntry{requesting_user_id: id}), do: true
  def can?(%User{id: id}, :show_feedback, %DnpEntry{requesting_user_id: id}), do: true

  def can?(_user, :show, %DnpEntry{aasm_state: "listed"}), do: true
  def can?(_user, :show_reason, %DnpEntry{aasm_state: "listed", hide_reason: false}), do: true

  # Create and edit galleries
  def can?(_user, :show, %Gallery{}), do: true
  def can?(%User{}, action, Gallery) when action in [:new, :create], do: true
  def can?(%User{id: id}, action, %Gallery{creator_id: id}) when action in [:edit, :update, :delete], do: true

  # Otherwise...
  def can?(_user, _action, _model), do: false
end
