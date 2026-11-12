using System.Text.Json.Serialization;

namespace CryptoPulse.Api.Models;

public sealed class SparklineDto
{
    [JsonPropertyName("price")] public List<double> Price { get; set; } = new();
}

/// <summary>Shape-compatible with CoinGecko's /coins/markets item (snake_case).</summary>
public class CoinDto
{
    [JsonPropertyName("id")] public string Id { get; set; } = "";
    [JsonPropertyName("symbol")] public string Symbol { get; set; } = "";
    [JsonPropertyName("name")] public string Name { get; set; } = "";
    [JsonPropertyName("image")] public string? Image { get; set; }
    [JsonPropertyName("current_price")] public double? CurrentPrice { get; set; }
    [JsonPropertyName("market_cap")] public double? MarketCap { get; set; }
    [JsonPropertyName("market_cap_rank")] public int? MarketCapRank { get; set; }
    [JsonPropertyName("total_volume")] public double? TotalVolume { get; set; }
    [JsonPropertyName("high_24h")] public double? High24h { get; set; }
    [JsonPropertyName("low_24h")] public double? Low24h { get; set; }
    [JsonPropertyName("price_change_percentage_24h")] public double? PriceChangePercentage24h { get; set; }
    [JsonPropertyName("circulating_supply")] public double? CirculatingSupply { get; set; }
    [JsonPropertyName("total_supply")] public double? TotalSupply { get; set; }
    [JsonPropertyName("max_supply")] public double? MaxSupply { get; set; }
    [JsonPropertyName("ath")] public double? Ath { get; set; }
    [JsonPropertyName("atl")] public double? Atl { get; set; }
    [JsonPropertyName("sparkline_in_7d")] public SparklineDto? SparklineIn7d { get; set; }
}

public sealed record ProfileDto(string Description, string Homepage, List<string> Categories);

public sealed class CoinDetailDto : CoinDto
{
    [JsonPropertyName("description")] public string Description { get; set; } = "";
    [JsonPropertyName("homepage")] public string Homepage { get; set; } = "";
    [JsonPropertyName("categories")] public List<string> Categories { get; set; } = new();
    [JsonPropertyName("source")] public string Source { get; set; } = "live";

    public static CoinDetailDto From(CoinDto c, ProfileDto p, string source) => new()
    {
        Id = c.Id, Symbol = c.Symbol, Name = c.Name, Image = c.Image,
        CurrentPrice = c.CurrentPrice, MarketCap = c.MarketCap, MarketCapRank = c.MarketCapRank,
        TotalVolume = c.TotalVolume, High24h = c.High24h, Low24h = c.Low24h,
        PriceChangePercentage24h = c.PriceChangePercentage24h,
        CirculatingSupply = c.CirculatingSupply, TotalSupply = c.TotalSupply, MaxSupply = c.MaxSupply,
        Ath = c.Ath, Atl = c.Atl, SparklineIn7d = c.SparklineIn7d,
        Description = p.Description, Homepage = p.Homepage, Categories = p.Categories, Source = source,
    };
}

public sealed record PagedResponse(
    [property: JsonPropertyName("data")] IReadOnlyList<CoinDto> Data,
    [property: JsonPropertyName("page")] int Page,
    [property: JsonPropertyName("per_page")] int PerPage,
    [property: JsonPropertyName("total")] int Total,
    [property: JsonPropertyName("has_more")] bool HasMore,
    [property: JsonPropertyName("source")] string Source);

public sealed record ChartResponse(
    [property: JsonPropertyName("id")] string Id,
    [property: JsonPropertyName("days")] int Days,
    [property: JsonPropertyName("prices")] IReadOnlyList<double[]> Prices,
    [property: JsonPropertyName("source")] string Source);

public sealed record DominanceDto(
    [property: JsonPropertyName("symbol")] string Symbol,
    [property: JsonPropertyName("share")] double Share);

public sealed record StatsResponse(
    [property: JsonPropertyName("total_market_cap")] double TotalMarketCap,
    [property: JsonPropertyName("total_volume")] double TotalVolume,
    [property: JsonPropertyName("market_cap_change_24h")] double MarketCapChange24h,
    [property: JsonPropertyName("btc_dominance")] double BtcDominance,
    [property: JsonPropertyName("eth_dominance")] double EthDominance,
    [property: JsonPropertyName("active_coins")] int ActiveCoins,
    [property: JsonPropertyName("gainers")] int Gainers,
    [property: JsonPropertyName("losers")] int Losers,
    [property: JsonPropertyName("dominance")] IReadOnlyList<DominanceDto> Dominance,
    [property: JsonPropertyName("top_gainers")] IReadOnlyList<CoinDto> TopGainers,
    [property: JsonPropertyName("top_losers")] IReadOnlyList<CoinDto> TopLosers,
    [property: JsonPropertyName("source")] string Source);
