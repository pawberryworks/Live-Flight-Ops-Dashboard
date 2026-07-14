using System.Text.Json;
using System.Text.Json.Serialization;

using LiveFlughtOpsDashboardBackend.DTO;

namespace LiveFlughtOpsDashboardBackend.Converters;

public sealed class AircraftStateJsonConverter
    : JsonConverter<AircraftState>
{
    public override AircraftState Read(
        ref Utf8JsonReader reader,
        Type typeToConvert,
        JsonSerializerOptions options)
    {
        using var document = JsonDocument.ParseValue(ref reader);
        var state = document.RootElement;

        if (state.ValueKind != JsonValueKind.Array)
        {
            throw new JsonException(
                "Aircraft state must be represented as an array.");
        }

        return new AircraftState
        {
            Icao24 = GetString(state, 0) ?? string.Empty,
            CallSign = GetString(state, 1)?.Trim() ?? string.Empty,
            OriginCountry = GetString(state, 2) ?? string.Empty,

            TimePosition = GetInt64(state, 3),
            LastContact = GetInt64(state, 4),

            Longitude = GetDouble(state, 5),
            Latitude = GetDouble(state, 6),
            BarometricAltitude = GetDouble(state, 7),

            OnGround = GetBoolean(state, 8) ?? false,

            Velocity = GetDouble(state, 9),
            TrueTrack = GetDouble(state, 10),
            VerticalRate = GetDouble(state, 11),

            Sensors = GetIntArray(state, 12),

            GeometricAltitude = GetDouble(state, 13),
            Squawk = GetString(state, 14),

            Spi = GetBoolean(state, 15) ?? false,
            PositionSource = GetInt32(state, 16) ?? 0,
            Category = GetInt32(state, 17) ?? 0
        };
    }

    public override void Write(
        Utf8JsonWriter writer,
        AircraftState value,
        JsonSerializerOptions options)
    {
        //writer.WriteStartArray();

        //writer.WriteStringValue(value.Icao24);
        //writer.WriteStringValue(value.CallSign);
        //writer.WriteStringValue(value.OriginCountry);

        //WriteNumberOrNull(writer, value.TimePosition);
        //WriteNumberOrNull(writer, value.LastContact);

        //WriteNumberOrNull(writer, value.Longitude);
        //WriteNumberOrNull(writer, value.Latitude);
        //WriteNumberOrNull(writer, value.BarometricAltitude);

        //writer.WriteBooleanValue(value.OnGround);

        //WriteNumberOrNull(writer, value.Velocity);
        //WriteNumberOrNull(writer, value.TrueTrack);
        //WriteNumberOrNull(writer, value.VerticalRate);

        //JsonSerializer.Serialize(writer, value.Sensors, options);

        //WriteNumberOrNull(writer, value.GeometricAltitude);

        //if (value.Squawk is null)
        //    writer.WriteNullValue();
        //else
        //    writer.WriteStringValue(value.Squawk);

        //writer.WriteBooleanValue(value.Spi);
        //writer.WriteNumberValue(value.PositionSource);

        //writer.WriteEndArray();
    }

    private static JsonElement? GetElement(JsonElement array, int index)
    {
        if (index >= array.GetArrayLength())
            return null;

        var element = array[index];

        return element.ValueKind == JsonValueKind.Null
            ? null
            : element;
    }

    private static string? GetString(JsonElement array, int index)
    {
        var element = GetElement(array, index);

        return element is { ValueKind: JsonValueKind.String }
            ? element.Value.GetString()
            : null;
    }

    private static long? GetInt64(JsonElement array, int index)
    {
        var element = GetElement(array, index);

        return element?.TryGetInt64(out var value) == true
            ? value
            : null;
    }

    private static int? GetInt32(JsonElement array, int index)
    {
        var element = GetElement(array, index);

        return element?.TryGetInt32(out var value) == true
            ? value
            : null;
    }

    private static double? GetDouble(JsonElement array, int index)
    {
        var element = GetElement(array, index);

        return element?.TryGetDouble(out var value) == true
            ? value
            : null;
    }

    private static bool? GetBoolean(JsonElement array, int index)
    {
        var element = GetElement(array, index);

        return element?.ValueKind switch
        {
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            _ => null
        };
    }

    private static int[]? GetIntArray(JsonElement array, int index)
    {
        var element = GetElement(array, index);

        if (element is not { ValueKind: JsonValueKind.Array })
            return null;

        return element.Value
            .EnumerateArray()
            .Where(x => x.TryGetInt32(out _))
            .Select(x => x.GetInt32())
            .ToArray();
    }

    //private static void WriteNumberOrNull(
    //    Utf8JsonWriter writer,
    //    long? value)
    //{
    //    if (value.HasValue)
    //        writer.WriteNumberValue(value.Value);
    //    else
    //        writer.WriteNullValue();
    //}

    //private static void WriteNumberOrNull(
    //    Utf8JsonWriter writer,
    //    double? value)
    //{
    //    if (value.HasValue)
    //        writer.WriteNumberValue(value.Value);
    //    else
    //        writer.WriteNullValue();
    //}
}