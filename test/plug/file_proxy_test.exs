defmodule Plug.FileProxyTest do
  alias Plug.FileProxy
  use ExUnit.Case, async: true
  use Plug.Test

  test "site_path not given" do
    assert_raise KeyError, fn ->
      FileProxy.init([base_url: "foo"])
    end
  end

  test "base_url not given" do
    assert_raise KeyError, fn ->
      FileProxy.init([site_path: "foo"])
    end
  end

  test "opts valid" do
    FileProxy.init([site_path: "foo", base_url: "baa"])
  end

  test "Non get method gives exception" do
    assert_raise FileProxy.InvalidMethodExecption, fn ->
      conn(:post, "/blog") |> FileProxy.call([])
    end
  end

  test "Path not matching base_url fails" do
    assert_raise FileProxy.PageNotFoundException, fn ->
      conn(:get, "/foo") |> FileProxy.call([base_url: "/baa"])
    end
  end

  test "Not existent file" do
    assert_raise FileProxy.PageNotFoundException, fn ->
      conn(:get, "/foo/baa")
      |> FileProxy.call([base_url: "/foo", site_path: "test/plug/", file_extension: ".html", default_path: "index"])
    end
  end

  test "Non-fragment file" do
    assert_raise FileProxy.NotFragmentException, fn ->
      conn(:get, "/foo/not-fragment")
      |> FileProxy.call([base_url: "/foo", site_path: "test/plug/", file_extension: ".html", default_path: "index", check_is_fragment?: true])
    end
  end

  test "Valid request for index" do
    conn =
    conn(:get, "/foo")
    |> FileProxy.call([base_url: "/foo", site_path: "test/plug/", file_extension: ".html", default_path: "index"])

    {:safe, body} = conn.assigns.file_proxy.body
    assert body =~ ~s{Index page}
    assert "meta1 content" == conn.assigns.file_proxy.metas[:meta1]
    assert "meta2 content" == conn.assigns.file_proxy.metas[:meta2]
  end

  test "Valid request for other page" do
    conn =
    conn(:get, "/foo/other")
    |> FileProxy.call([base_url: "/foo", site_path: "test/plug/", file_extension: ".html", default_path: "index"])

    {:safe, body} = conn.assigns.file_proxy.body
    assert body =~ ~s{Other page}
  end

  test "Extract metas" do
    raw_body = """
    <meta name="meta1" content="meta1 content">
    <meta name="meta2" content="meta2 content">
    Some text
    """
    req = FileProxy.extract_metas(%FileProxy{raw_body: raw_body}, [])
    assert "meta1 content" == req.metas[:meta1]
    assert "meta2 content" == req.metas[:meta2]
    assert {:safe,"Some text\n"} == req.body
  end
end
