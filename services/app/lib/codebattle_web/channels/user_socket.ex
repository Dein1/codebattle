defmodule CodebattleWeb.UserSocket do
  use Phoenix.Socket

  require Logger
  ## Channels
  channel("lobby", CodebattleWeb.LobbyChannel)
  channel("game:*", CodebattleWeb.GameChannel)
  channel("chat:*", CodebattleWeb.ChatChannel)

  ## Transports
  transport(:websocket, Phoenix.Transports.WebSocket, timeout: :infinity)
  # transport :longpoll, Phoenix.Transports.LongPoll

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(%{"token" => user_token}, socket) do
    case Phoenix.Token.verify(socket, "user_token", user_token, max_age: 1_000_000) do
      {:ok, 0} ->
        socket = assign(socket, :current_user, Codebattle.Bot.Builder.build())
        {:ok, assign(socket, :user_id, 0)}

      {:ok, "anonymous"} ->
        socket =
          assign(socket, :current_user, %Codebattle.User{
            guest: true,
            id: "anonymous",
            name: "Anonymous"
          })

        {:ok, assign(socket, :user_id, "anonymous")}

      {:ok, user_id} ->
        user = Codebattle.User |> Codebattle.Repo.get!(user_id)
        socket = assign(socket, :current_user, user)
        {:ok, assign(socket, :user_id, user_id)}

      {:error, _reason} ->
        Logger.error(_reason)
        socket = assign(socket, :current_user, "guest")
        {:ok, assign(socket, :user_id, "guest")}
    end
  end

  # Socket id's are topics that allow you to identify all
  # sockets for a given user:
  #
  #     def id(socket), do: "users_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #  Codebattle.Endpoint.broadcast("users_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil
end
