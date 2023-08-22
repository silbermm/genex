defmodule Genex.Case do
  @moduledoc false
  use ExUnit.CaseTemplate

  setup _ do
    # If we don't define any expectations, call the real implementation of GPG.NativeAPI (GPG.Rust.NIF)
    Mox.stub_with(GPG.MockNativeAPI, GPG.Rust.GPG)
    :ok
  end
end
