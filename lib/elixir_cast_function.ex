defmodule ElixirCastFunction do
  @moduledoc """
    Fetch Elixirlang cast function from hexdoc.
  """

  @target "https://hexdocs.pm/elixir/"


  def run do
     fetch()
     |> pick()
     |> convert()
     |> output()
  end


  @doc """
  fetch elixir document html from hexdoc.

  ## Examples

      iex> ElixirCastFunction.fetch()
  """
  def fetch do
    Req.get!(@target <> "Kernel.html").body 
    |> Floki.parse_document!()
    |> Floki.find("script[src^='dist/sidebar_items']")
    |> Floki.attribute("src")
    |> List.insert_at(0, @target)
    |> to_string()
    |> Req.get!()
    |> Map.get(:body)
  end

  @doc """
  pick up functions dom elements.

  ## Examples

      iex> ElixirCastFunction.pick()
  """
  def pick(elixir_function_js) do
    json = String.replace_prefix(elixir_function_js, "sidebarNodes=", "") |> Jason.decode!

    has_node_groups = json["modules"] 
                    |> Enum.filter(fn x -> Map.has_key?(x, "nodeGroups") end)

    has_node_groups |> Enum.map(fn x -> { 
                    # key
                    Map.get(x, "id") |> String.to_atom(),
                    # value
                    Map.get(x, "nodeGroups", [])
                    |> List.last(%{}) 
                    |> Map.get("nodes", []) 
                    |> Enum.map(fn x -> Map.get(x, "id") end)
                    } end)
                    |> Enum.map(fn {id, funs} -> {id, Enum.filter(funs, fn x -> String.contains?(x, ["to_", "from"]) end)}end)  # to/from を含んだモジュールを探す
                    |> Enum.filter(fn {_, x} -> length(x) > 0 end) # to/fromを持つリストだけ取り出す
  end

  @doc """
  convert module data to markdown table.

  ## Examples

      iex> ElixirCastFunction.convert()
  """
  def convert(module_list) do
    # h <> t がイケてない気がするので、ヘッダーをモジュール属性にするか、
    # パイプラインで処理する
    h = "| Module | Function |\n| :-: | --- |\n"
    t = module_list |> Enum.flat_map(fn {m, f} -> [m] ++  Enum.intersperse(f, "") end)
                |> Enum.chunk_every(2) # [[:a, 1], ["", 2], ["", 3]]
                |> Enum.map(fn [x, n] -> "| #{x} | #{n} |" end ) 
                |> Enum.join("\n") # "| a | 1 |\n|  | 2 |\n|  | 3 |"
    h <> t
  end 

  @doc """
  output markdown table.

  ## Examples

      iex> ElixirCastFunction.output()
  """
  def output(markdown) do
    IO.puts markdown
  end
end
