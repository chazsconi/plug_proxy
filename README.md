# PlugProxy

This contains the following plugs that proxy the request:
- `Plug.FileProxy` - proxies requests to a static file system.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `plug_proxy` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:plug_proxy, "~> 0.1.0"}]
    end
    ```

## FileProxy

Proxies the requests to a static file system and places the content of the files in the `assigns.file_proxy`.  Can be used to integrate with a static file system such as Jekyll.

To use:

### Configure router

Forward all routes to a controller

```elixir
forward "/blog", BlogController, :index
```

### Add a controller

Configure the proxy with the URL (should match the routes), and where the files are on the file system.

```elixir
defmodule MyApp.BlogController do
  use Phoenix.Controller
  plug Plug.FileProxy, [base_url: "/blog", site_path: "../jekyll/_site"]

  def index(conn, _params) do
    render conn, "index.html"
  end
```

### Create a view and template

```elixir
defmodule MyApp.BlogView do
  use MyApp.Web, :view
end
```

```html
<div class="container">
  <%= @file_proxy.body %>
</div>
```

### Passing meta data from the file system

Any meta tags in the file that is read are converted into a map and placed in `assigns.file_proxy.metas`

e.g.
```html
<meta name="description" content="My blog">
<meta name="keywords" content="blog elixir">
```

Will set have `metas` set to `%{description: "My blog", keywords: "blog elixir"}`

A page title can be passed in a similar way (but then this needs to be somehow transferred to the layout).

### Configuration options

#### Page fragments
By default the proxy expects no <html>, <head> or <body> tags.  This will cause an exception.  This behaviour can be changed by setting `check_is_fragment?: false`

#### File extension
The files served should have the `.html` extension, although the routes used strip the extension.

## TODO
- [ ] Serve images and other assets
