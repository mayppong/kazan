defmodule Kazan.Models do
  @moduledoc """
  Contains generated structs for all Kube models as defined in the OAI specs.

  Also contains tools for serializing & deserializing these generated structs.

  See Kazan.Codegen for the actual code generation details.
  """
  require Kazan.Codegen.Models
  alias Kazan.Codegen
  alias Kazan.Codegen.Models.{ModelDesc, PropertyDesc}

  Codegen.Models.from_spec("kube_specs/swagger.json")

  @doc """
  Decodes data from a Map into a Model struct.
  """
  @spec decode(Map.t, atom | nil) :: {:ok, struct} | {:err, term}
  def decode(data, kind \\ nil) do
    with {:ok, kind} <- guess_kind(data, kind),
         {:ok, desc} <- model_desc(kind),
         {:ok, model} <- do_decode(desc, data),
         do: {:ok, model}
  end

  @doc """
  Encodes data from a Kazan model to plain Maps suitable for JSON encoding.
  """
  @spec encode(struct) :: {:ok, struct} | {:err, term}
  def encode(model) do
    with {:ok, desc} <- model_desc(model.__struct__),
         {:ok, data} <- do_encode(desc, model),
         do: {:ok, data}
  end

  @spec guess_kind(Map.t, atom | nil) :: {:ok, atom} | {:err, term}
  defp guess_kind(data, kind) do
    cond do
      kind -> {:ok, kind}
      Map.has_key?(data, "kind") and Map.has_key?(data, "apiVersion") ->
        version = data["apiVersion"] |> String.split("/") |> List.last
        {:ok, Kazan.Codegen.Models.module_name("#{version}.#{data["kind"]}")}
      :otherwise ->
        {:err, :missing_kind}
    end
  end

  @spec model_desc(atom) :: {:ok, ModelDesc.t} | {:err, term}
  defp model_desc(kind) do
    case Map.get(model_descs, kind) do
      nil -> {:err, {:unknown_model, kind}}
      model_desc -> {:ok, model_desc}
    end
  end

  @spec do_decode(ModelDesc.t, Map.t) :: {:ok, struct} | {:err, term}
  defp do_decode(model_desc, data) do
    result =
      model_desc.properties
      |> map_ok(fn ({name, property_desc}) ->
        property =
          data
          |> Map.get(property_desc.field)
          |> decode_property(property_desc)

        case property do
          {:ok, property} -> {:ok, {name, property}}
          {:err, _} = err -> err
        end
      end)

    case result do
      {:ok, properties} ->
        {:ok, struct!(model_desc.module_name, properties)}
      {:err, _} = err ->
        err
    end
  end

  @spec decode_property(term, PropertyDesc.t) :: {:ok, term} | {:err, term}
  defp decode_property(value, property_desc)
  defp decode_property(nil, _), do: {:ok, nil}
  defp decode_property(value, %{type: "string"}), do: {:ok, value}
  defp decode_property(value, %{type: "boolean"}), do: {:ok, value}
  defp decode_property(value, %{type: "integer"}), do: {:ok, value}
  defp decode_property(value, %{type: "object"}), do: {:ok, value}

  defp decode_property(value, %{type: "array", items: items}) do
    map_ok(value, &decode_property(&1, items))
  end
  defp decode_property(value, %{type: nil, ref: ref}) do
    decode(value, ref)
  end
  defp decode_property(_value, %{type: type}) do
    {:err, {:unknown_property_type, type}}
  end

  @spec do_encode(ModelDesc.t, struct) :: {:ok, Map.t} | {:err, term}
  defp do_encode(model_desc, model) do
    result =
      model_desc.properties
      |> map_ok(fn ({name, property_desc}) ->
        property =
          model
          |> Map.get(name)
          |> encode_property(property_desc)

        case property do
          {:ok, property} -> {:ok, {property_desc.field, property}}
          {:err, _} = err -> err
        end
      end)

      case result do
        {:ok, properties} ->
          {:ok, Enum.into(properties, %{})}
        {:err, _} = err ->
          err
      end
  end

  @spec encode_property(term, PropertyDesc.t) :: {:ok, term} | {:err, term}
  defp encode_property(value, property_desc)
  defp encode_property(nil, _), do: {:ok, nil}
  defp encode_property(value, %{type: "string"}), do: {:ok, value}
  defp encode_property(value, %{type: "boolean"}), do: {:ok, value}
  defp encode_property(value, %{type: "integer"}), do: {:ok, value}
  defp encode_property(value, %{type: "object"}), do: {:ok, value}

  defp encode_property(value, %{type: "array", items: items}) do
    map_ok(value, &encode_property(&1, items))
  end
  defp encode_property(value, %{type: nil}) do
    encode(value)
  end
  defp encode_property(_, %{type: type}) do
    {:err, {:unknown_property_type, type}}
  end


  # map_ok acts like Enum.map, but for functions that can return {:ok, x} or
  # {:err, err}.  It also returns {:ok, res} or {:err, err}
  defp map_ok(enumerable, fun) do
    res = Enum.reduce_while(enumerable, [], fn (elem, acc) ->
      case fun.(elem) do
        {:ok, res} -> {:cont, [res|acc]}
        {:err, err} -> {:halt, {:err, err}}
      end
    end)

    case res do
      {:err, _} = err -> err
      results -> {:ok, Enum.reverse(results)}
    end
  end
end