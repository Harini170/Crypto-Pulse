using CryptoPulse.Api.Models;
using CryptoPulse.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace CryptoPulse.Api.Endpoints;

public static class CoinEndpoints
{
    private static readonly int[] AllowedDays = { 1, 7, 30, 90, 365 };

    public static IEndpointRouteBuilder MapCryptoEndpoints(this IEndpointRouteBuilder app)
    {
        var api = app.MapGroup("/api").WithTags("Crypto Pulse");

        api.MapGet("/health", () => Results.Ok(new { status = "ok", time = DateTime.UtcNow }))
            .WithSummary("Liveness check");

        // GET /api/coins?page=1&per_page=20&q=bit&sort=market_cap&order=desc&filter=all&ids=a,b
        api.MapGet("/coins", async (
            IMarketProvider provider,
            [FromQuery] int? page,
            [FromQuery(Name = "per_page")] int? perPage,
            [FromQuery] string? q,
            [FromQuery] string? sort,
            [FromQuery] string? order,
            [FromQuery] string? filter,
            [FromQuery] string? ids,
            CancellationToken ct) =>
        {
            var (coins, source) = await provider.GetMarketsAsync(ct);
            var pageNo = Math.Max(1, page ?? 1);
            var size = Math.Clamp(perPage ?? 20, 1, 250);
            var asc = string.Equals(order, "asc", StringComparison.OrdinalIgnoreCase);
            var query = (q ?? "").Trim();
            var idSet = (ids ?? "").Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

            IEnumerable<CoinDto> list = coins;
            if (idSet.Length > 0) list = list.Where(c => idSet.Contains(c.Id));
            if (query.Length > 0)
                list = list.Where(c =>
                    c.Name.Contains(query, StringComparison.OrdinalIgnoreCase) ||
                    c.Symbol.Contains(query, StringComparison.OrdinalIgnoreCase));

            switch (filter)
            {
                case "gainers": list = list.Where(c => (c.PriceChangePercentage24h ?? 0) > 0); break;
                case "losers": list = list.Where(c => (c.PriceChangePercentage24h ?? 0) < 0); break;
                case "high_volume":
                    var vols = coins.Select(c => c.TotalVolume ?? 0).OrderBy(v => v).ToList();
                    var median = vols.Count == 0 ? 0 : vols[vols.Count / 2];
                    list = list.Where(c => (c.TotalVolume ?? 0) > median);
                    break;
            }

            list = sort switch
            {
                "price" => Order(list, c => c.CurrentPrice ?? 0, asc),
                "volume" => Order(list, c => c.TotalVolume ?? 0, asc),
                "change" => Order(list, c => c.PriceChangePercentage24h ?? 0, asc),
                "name" => Order(list, c => c.Name.ToLowerInvariant(), asc),
                _ => Order(list, c => c.MarketCap ?? 0, asc),
            };

            var all = list.ToList();
            var skip = (pageNo - 1) * size;
            var data = all.Skip(skip).Take(size).ToList();
            return Results.Ok(new PagedResponse(data, pageNo, size, all.Count, skip + size < all.Count, source));
        }).WithSummary("Paged, searchable, filterable, sortable coin list");

        // GET /api/coins/{id}
        api.MapGet("/coins/{id}", async (string id, IMarketProvider provider, CancellationToken ct) =>
        {
            var (coins, source) = await provider.GetMarketsAsync(ct);
            var coin = coins.FirstOrDefault(c => c.Id == id);
            if (coin is null) return Results.NotFound(new { message = $"Coin \"{id}\" not found" });
            var profile = await provider.GetProfileAsync(id, ct);
            return Results.Ok(CoinDetailDto.From(coin, profile, source));
        }).WithSummary("Coin details (market data, description, categories)");

        // GET /api/coins/{id}/chart?days=7
        api.MapGet("/coins/{id}/chart", async (string id, [FromQuery] int? days, IMarketProvider provider,
            CancellationToken ct) =>
        {
            var d = days is not null && AllowedDays.Contains(days.Value) ? days.Value : 7;
            var (prices, source) = await provider.GetChartAsync(id, d, ct);
            return Results.Ok(new ChartResponse(id, d, prices, source));
        }).WithSummary("Price history for charts (days = 1, 7, 30, 90, 365)");

        // GET /api/market/stats
        api.MapGet("/market/stats", async (IMarketProvider provider, CancellationToken ct) =>
        {
            var (coins, source) = await provider.GetMarketsAsync(ct);
            var totalCap = coins.Sum(c => c.MarketCap ?? 0);
            var totalVol = coins.Sum(c => c.TotalVolume ?? 0);
            var weighted = coins.Sum(c => (c.MarketCap ?? 0) * (c.PriceChangePercentage24h ?? 0));

            double Share(string sym)
            {
                var c = coins.FirstOrDefault(x => x.Symbol == sym);
                return c is null || totalCap == 0 ? 0 : (c.MarketCap ?? 0) / totalCap * 100;
            }

            var top = coins.OrderByDescending(c => c.MarketCap ?? 0).Take(5)
                .Select(c => new DominanceDto(c.Symbol.ToUpperInvariant(),
                    totalCap == 0 ? 0 : (c.MarketCap ?? 0) / totalCap * 100))
                .ToList();
            top.Add(new DominanceDto("Others", Math.Max(0, 100 - top.Sum(t => t.Share))));

            var byChange = coins.OrderByDescending(c => c.PriceChangePercentage24h ?? 0).ToList();
            return Results.Ok(new StatsResponse(
                totalCap, totalVol,
                totalCap == 0 ? 0 : weighted / totalCap,
                Share("btc"), Share("eth"), coins.Count,
                coins.Count(c => (c.PriceChangePercentage24h ?? 0) > 0),
                coins.Count(c => (c.PriceChangePercentage24h ?? 0) < 0),
                top,
                byChange.Take(5).ToList(),
                byChange.TakeLast(5).Reverse().ToList(),
                source));
        }).WithSummary("Global market statistics, dominance and top movers");

        return app;
    }

    private static IOrderedEnumerable<CoinDto> Order<TKey>(IEnumerable<CoinDto> src, Func<CoinDto, TKey> key, bool asc)
        => asc ? src.OrderBy(key) : src.OrderByDescending(key);
}
