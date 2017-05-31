defmodule Gateway.PresenceChannelTest do
  use ExUnit.Case, async: true
  use Gateway.ChannelCase
  alias Gateway.PresenceChannel
  alias Gateway.Presence

  test "a user connecting to her own topic works" do
    assert {:ok, _response, sock} = subscribe_and_join_user(
      "testuser",
      ["customer"],
      "user:testuser"
    )
    leave sock
  end

  test "a user connecting to someone else's topic with not authorised role fails" do
    assert {:error, _message} = subscribe_and_join_user(
      "foo-user",
      ["customer"],
      "user:bar-user"
    )
  end

  test "a user connecting to someone else's topic with authorised role works" do
    assert {:ok, _response, sock} = subscribe_and_join_user(
      "foo-user",
      ["support"],
      "user:testuser"
    )
    leave sock
  end

  test "a user connecting to role specific topic with authorised role works" do
    assert {:ok, _response, sock} = subscribe_and_join_user(
      "foo-user",
      ["support"],
      "role:customer"
    )
    leave sock
  end

  test "a user connecting to role specific topic without authorised role fails" do
    assert {:error, _message} = subscribe_and_join_user(
      "foo-user",
      ["customer"],
      "role:customer"
    )
  end

  test "a user joining/leaving channel should be tracked by presence" do
    assert {:ok, _response, sock} = subscribe_and_join_user(
      "testuser",
      ["customer"],
      "user:testuser"
    )

    assert Map.has_key?(Presence.list("role:customer"), "testuser")
    Process.unlink(sock.channel_pid)
    close sock
    assert !Map.has_key?(Presence.list("role:customer"), "testuser")
  end

  defp subscribe_and_join_user(username, roles, topic) do
    token_info_customer = %{"username" => username, "role" => roles}
    socket("", %{user_info: token_info_customer})
    |> subscribe_and_join(PresenceChannel, topic)
  end
end
