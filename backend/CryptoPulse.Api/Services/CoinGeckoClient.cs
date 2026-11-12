using System.Globalization;
using System.Text.Json;
using CryptoPulse.Api.Models;

namespace CryptoPulse.Api.Services;

/// <summary>Typed HttpClient for the public CoinGecko v3 API.</summary>
public sealed class CoinGeckoClient
{
    private readonly HttpClient _http;

    public CoinGeckoClient(HttpClient http, IConfiguration config)
    {
        _http = http;
        _http.BaseAddress = new Uri("https://api.coingecko.com/api/v3/");
        _http.Timeout = TimeSpan.FromSeconds(8);
        _http.DefaultRequestHeaders.Accept.ParseAdd("application/json");
        _http.DefaultRequestHeaders.UserAgent.ParseAdd("CryptoPulse/1.0");
        var key = config["Market:CoinGeckoApiKey"];
        if (!string.IsNullOrWhiteSpace(key)) _http.DefaultRequestHeaders.Add("x-cg-demo-api-key", key);
    }

    public async Task<List<CoinDto>> GetMarketsAsync(CancellationToken ct)
    {
        using var res = await _http.GetAsync(
            "coins/markets?vs_currency=usd&order=market_cap_desc&per_page=250&page=1&sparkline=true&price_change_percentage=24h", ct);
        res.EnsureSuccessStatusCode();
        await using var stream = await res.Content.ReadAsStreamAsync(ct);
        return await JsonSerializer.DeserializeAsync<List<CoinDto>>(stream, cancellationToken: ct) ?? new();
    }

    public async Task<List<double[]>> GetChartAsync(string id, int days, CancellationToken ct)
    {
        using var res = await _http.GetAsync(
            $"coins/{Uri.EscapeDataString(id)}/market_chart?vs_currency=usd&days={days.ToString(CultureInfo.InvariantCulture)}", ct);
        res.EnsureSuccessStatusCode();
        await using var stream = await res.Content.ReadAsStreamAsync(ct);
        using var doc = await JsonDocument.ParseAsync(stream, cancellationToken: ct);
        var list = new List<double[]>();
        foreach (var p in doc.RootElement.GetProperty("prices").EnumerateArray())
            list.Add(new[] { p[0].GetDouble(), p[1].GetDouble() });
        return list;
    }

    public async Task<ProfileDto> GetProfileAsync(string id, CancellationToken ct)
    {
        using var res = await _http.GetAsync(
            $"coins/{Uri.EscapeDataString(id)}?localization=false&tickers=false&market_data=false&community_data=false&developer_data=false&sparkline=false", ct);
        res.EnsureSuccessStatusCode();
        await using var stream = await res.Content.ReadAsStreamAsync(ct);
        using var doc = await JsonDocument.ParseAsync(stream, cancellationToken: ct);
        var root = doc.RootElement;

        var description = root.TryGetProperty("description", out var d) && d.TryGetProperty("en", out var en)
            ? en.GetString() ?? "" : "";
        var homepage = "";
        if (root.TryGetProperty("links", out var links) && links.TryGetProperty("homepage", out var hp)
            && hp.ValueKind == JsonValueKind.Array && hp.GetArrayLength() > 0)
            homepage = hp[0].GetString() ?? "";
        var categories = new List<string>();
        if (root.TryGetProperty("categories", out var cats) && cats.ValueKind == JsonValueKind.Array)
            categories = cats.EnumerateArray().Select(e => e.GetString())
                .Where(s => !string.IsNullOrWhiteSpace(s)).Take(4).Select(s => s!).ToList();
        return new ProfileDto(description, homepage, categories);
    }
}
