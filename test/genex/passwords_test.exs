defmodule Genex.PasswordsTest do
  use ExUnit.Case

  alias Genex.Passwords
  alias Genex.Store.Settings

  @passphrase_key "test/user"

  setup :with_settings
 
  describe "when saving a passphrase" do
    test "then it is saved in the db store", %{settings: settings} do
      assert {:ok, secret} = save_passphrase(@passphrase_key, settings)

      assert !is_nil(secret.id)
      assert secret.key == key
      assert secret.action == :insert
    end

    @tag gpg_email: "invalid@invalid.com"
    test "then an invalid email in settings returns encryption error", %{settings: settings} do
      assert {:error, err_msg} = save_passphrase(@passphrase_key, settings)
      assert err_msg =~ "gpg error"
    end
  end


  describe "when listing saved passphrases for a profile" do
    @tag profile: "testing_list_func_v1"
    test "then initially the store is empty", %{settings: settings} do
      assert [] == Passwords.all(profile: settings.profile)
    end
 
    @tag profile: "test_list_func_v2"
    test "then after adding a passphrase, it is returned when listing", %{settings: settings} do
      assert {:ok, secret} = save_passphrase(@passphrase_key, settings)
      assert [secret] == Passwords.all(profile: settings.profile)
    end

    @tag profile: "test_list_func_v2"
    test "then after updating a passphrase, it is only returned once", %{settings: settings} do
      assert {:ok, secret} = save_passphrase(@passphrase_key, settings)
      assert [secret] == Passwords.all(profile: settings.profile)
    end
  end

  defp save_passphrase(key, settings) do
    phrase = Diceware.generate()
    Passwords.save(key, phrase, settings)
  end

  defp with_settings(context) do
    profile = Map.get(context, :profile, "default")
    email = Map.get(context, :gpg_email, "test@test.com")

    %{settings: %Settings{profile: profile, gpg_email: email, password_length: 6}}
  end
end
