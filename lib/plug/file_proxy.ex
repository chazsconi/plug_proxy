defmodule Plug.FileProxy do
  require Logger
  alias Plug.FileProxy

  @metas_regex ~r/<meta name="(.*)" content="(.*)">\s*/

  defstruct url: nil, raw_body: nil, body: nil, metas: %{}

  defmodule PageNotFoundException, do: defexception plug_status: 404, message: "Page not found"
  defmodule NotFragmentException, do: defexception plug_status: 500, message: "Returned HTML is not a page fragment"
  defmodule InvalidMethodExecption, do: defexception plug_status: 500, message: "Invalid method.  Only GET supported."

  def init(opts) do
    defaults = [check_is_fragment?: true, default_path: "/index", file_extension: ".html"]
    Keyword.fetch!(opts, :site_path)
    Keyword.fetch!(opts, :base_url)
    Keyword.merge(defaults, opts)
  end

  @doc "Proxies the request to the remote host and sets the response in :proxy_body"
  def call(conn, opts) do
    req =
      %FileProxy{}
      |> check_method!(conn, opts)
      |> put_url!(conn, opts)
      |> load_request!(opts)
      |> check_is_fragment!(opts)
      |> extract_metas(opts)

    conn
    |> Plug.Conn.assign(:file_proxy, req)
  end

  @doc "Extracts metas for the raw body"
  def extract_metas(%FileProxy{raw_body: raw_body}=req, _opts) do
    metas =
      Regex.scan(@metas_regex, raw_body, capture: :all_but_first)
      |> Enum.reduce(%{},
          fn([k, v], map) ->
            Map.put(map, String.to_atom(k), v)
          end)

    body =Regex.replace(@metas_regex, raw_body, "")
    %FileProxy{ req | metas: metas, body: {:safe, body}}
  end
  # Checks if the HTML is a page fragment and raises and exception if it is not
  defp check_is_fragment!(%FileProxy{raw_body: body}=req, opts) do
    if opts[:check_is_fragment?] do
      # This is crude but the alternative is to parse the page
      if Regex.match?(~r/<html[\s>]|<body[\s>]|<head[\s>]/, body) do
        raise NotFragmentException
      end
    end
    req
  end

  # Adds the url to the request
  defp put_url!(%FileProxy{}=req, conn, opts) do
    base_url = opts[:base_url]
    if String.starts_with?(conn.request_path, [base_url]) do
      case String.trim_leading(conn.request_path, base_url) do
        ""  -> %FileProxy{ req | url: opts[:default_path]}
        url -> %FileProxy{ req | url: url}
      end
    else
      raise PageNotFoundException
    end
  end

  defp check_method!(%FileProxy{}=req, conn, _opts) do
    if conn.method != "GET" do
      raise InvalidMethodExecption
    end
    req
  end

  # loads the requested file
  defp load_request!(%FileProxy{url: url}=req, opts) do
    file_path = opts[:site_path] <> url <> opts[:file_extension]
    Logger.info "FileProxy: GET #{url} from #{file_path}"
    case File.read(file_path) do
      {:ok, body}       -> %FileProxy{req | raw_body: body}
      {:error, :enoent} -> raise PageNotFoundException
    end
  end
end
