using System.Net;
using System.Text.Json;
using CryptoPulse.Api.Models;
using Microsoft.Extensions.Caching.Memory;

namespace CryptoPulse.Api.Services;

public interface IMarketProvider
{
    Task<(List<CoinDto> Coins, string Source)> GetMarketsAsync(CancellationToken ct);
    Task<(IReadOnlyList<double[]> Prices, string Source)> GetChartAsync(string id, int days, CancellationToken ct);
    Task<ProfileDto> GetProfileAsync(string id, CancellationToken ct);
}

/// <summary>
/// Serves live CoinGecko data (cached to respect rate limits) and transparently
/// falls back to the built-in mock market when the API is unreachable / rate-limited.
/// </summary>
public sealed class MarketProvider : IMarketProvider
{
    private static readonly TimeSpan MarketsTtl = TimeSpan.FromSeconds(60);
    private static readonly TimeSpan ChartTtl = TimeSpan.FromMinutes(2);
    private static readonly TimeSpan ProfileTtl = TimeSpan.FromMinutes(10);
    private static readonly TimeSpan Cooldown = TimeSpan.FromSeconds(60);

    private readonly CoinGeckoClient _gecko;
    private readonly IMemoryCache _cache;
    private readonly ILogger<MarketProvider> _log;
    private readonly bool _forceMock;
    private readonly SemaphoreSlim _marketsLock = new(1, 1);
    private DateTimeOffset _liveDownUntil = DateTimeOffset.MinValue;

    public MarketProvider(CoinGeckoClient gecko, IMemoryCache cache, IConfiguration config,
        ILogger<MarketProvider> log)
    {
        _gecko = gecko;
        _cache = cache;
        _log = log;
        _forceMock = config.GetValue<bool>("Market:UseMock");
    }

    private bool LiveAvailable => !_forceMock && DateTimeOffset.UtcNow >= _liveDownUntil;

    private void MarkLiveDown(Exception ex)
    {
        _log.LogWarning("Live API unavailable ({Message}); using mock data for {Seconds}s",
            ex.Message, Cooldown.TotalSeconds);
        _liveDownUntil = DateTimeOffset.UtcNow + Cooldown;
    }

    private static bool IsNotFound(Exception ex) =>
        ex is HttpRequestException { StatusCode: HttpStatusCode.NotFound };

    private static bool IsTransient(Exception ex, CancellationToken ct) =>
        !ct.IsCancellationRequested && (ex is HttpRequestException || ex is TaskCanceledException || ex is JsonException);

    public async Task<(List<CoinDto> Coins, string Source)> GetMarketsAsync(CancellationToken ct)
    {
        if (LiveAvailable)
        {
            try
            {
                if (_cache.TryGetValue("markets", out List<CoinDto>? hit) && hit is not null)
                    return (hit, "live");

                await _marketsLock.WaitAsync(ct);
                try
                {
                    if (_cache.TryGetValue("markets", out hit) && hit is not null) return (hit, "live");
                    var fresh = await _gecko.GetMarketsAsync(ct);
                    _cache.Set("markets", fresh, MarketsTtl);
                    return (fresh, "live");
                }
                finally { _marketsLock.Release(); }
            }
            catch (Exception ex) when (IsTransient(ex, ct)) { MarkLiveDown(ex); }
        }
        return (MockMarket.GetMarkets(), "mock");
    }

    public async Task<(IReadOnlyList<double[]> Prices, string Source)> GetChartAsync(
        string id, int days, CancellationToken ct)
    {
        if (LiveAvailable)
        {
            var key = $"chart:{id}:{days}";
            try
            {
                if (_cache.TryGetValue(key, out List<double[]>? hit) && hit is not null) return (hit, "live");
                var fresh = await _gecko.GetChartAsync(id, days, ct);
                _cache.Set(key, fresh, ChartTtl);
                return (fresh, "live");
            }
            catch (Exception ex) when (IsNotFound(ex)) { /* unknown id on live API -> mock */ }
            catch (Exception ex) when (IsTransient(ex, ct)) { MarkLiveDown(ex); }
        }
        return (MockMarket.GetChart(id, days), "mock");
    }

    public async Task<ProfileDto> GetProfileAsync(string id, CancellationToken ct)
    {
        if (LiveAvailable)
        {
            var key = $"profile:{id}";
            try
            {
                if (_cache.TryGetValue(key, out ProfileDto? hit) && hit is not null) return hit;
                var fresh = await _gecko.GetProfileAsync(id, ct);
                _cache.Set(key, fresh, ProfileTtl);
                return fresh;
            }
            catch (Exception ex) when (IsNotFound(ex)) { /* fall through to mock profile */ }
            catch (Exception ex) when (IsTransient(ex, ct)) { MarkLiveDown(ex); }
        }
        return MockMarket.GetProfile(id);
    }
}
