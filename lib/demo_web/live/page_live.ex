defmodule DemoWeb.PageLive do
  use DemoWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    IO.puts("mounted")
    if connected?(socket), do: :timer.send_interval(30_000, self(), :update_clock)

    {:ok, assign(socket, query: "", results: %{}, hide: false, clock: "in the next 30s or so")}
  end

  def handle_info(:update_clock, socket) do
    IO.puts("updating clock!")
    {:noreply, assign(socket, clock: DateTime.utc_now())}
  end

  @impl true
  def handle_params(%{"hide" => "1"} = params, _url, socket) do
    IO.puts("hiding")
    {:noreply, assign(socket, hide: true)}
  end

  def handle_params(%{"hide" => "0"}, _url, socket) do
    IO.puts("showing")
    {:noreply, assign(socket, hide: false)}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("suggest", %{"q" => query}, socket) do
    {:noreply, assign(socket, results: search(query), query: query)}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    case search(query) do
      %{^query => vsn} ->
        {:noreply, redirect(socket, external: "https://hexdocs.pm/#{query}/#{vsn}")}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "No dependencies found matching \"#{query}\"")
         |> assign(results: %{}, query: query)}
    end
  end

  defp search(query) do
    if not DemoWeb.Endpoint.config(:code_reloader) do
      raise "action disabled when not in development"
    end

    for {app, desc, vsn} <- Application.started_applications(),
        app = to_string(app),
        String.starts_with?(app, query) and not List.starts_with?(desc, ~c"ERTS"),
        into: %{},
        do: {app, vsn}
  end
end
