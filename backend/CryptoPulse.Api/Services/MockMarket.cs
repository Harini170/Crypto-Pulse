using CryptoPulse.Api.Models;

namespace CryptoPulse.Api.Services;

/// <summary>
/// Deterministic "live" mock market. Prices are pure functions of time, so the list,
/// the 24h change, the sparkline and the detail chart are always consistent and keep moving.
/// </summary>
public static class MockMarket
{
    private const double Day = 86_400_000;
    private const double Hour = 3_600_000;

    private sealed record MockCoin(
        string Id, string Symbol, string Name, double Price, double Circ, double? Max, bool Stable,
        double[] S, double Vol, double VolRatio, double AthMul, double AtlMul, uint Seed);

    private sealed class Rng
    {
        private uint _a;
        public Rng(uint seed) => _a = seed;

        public double Next()
        {
            unchecked
            {
                _a += 0x6D2B79F5;
                var t = (_a ^ (_a >> 15)) * (_a | 1);
                t = (t + (t ^ (t >> 7)) * (t | 61)) ^ t;
                return (t ^ (t >> 14)) / 4294967296.0;
            }
        }
    }

    private static uint Hash(string s)
    {
        unchecked
        {
            uint h = 2166136261;
            foreach (var ch in s) { h ^= ch; h *= 16777619; }
            return h;
        }
    }

    private static MockCoin Make(string id, string symbol, string name, double price, double circ,
        double? max, bool stable = false)
    {
        var seed = Hash(id);
        var r = new Rng(seed);
        var s = new[] { r.Next() * 6.28, r.Next() * 6.28, r.Next() * 6.28, r.Next() * 6.28, r.Next() * 6.28 };
        return new MockCoin(id, symbol, name, price, circ, max, stable, s,
            0.5 + r.Next() * 1.5, 0.02 + r.Next() * 0.07, 1.15 + r.Next() * 1.6, 0.002 + r.Next() * 0.15, seed);
    }

    private static readonly List<MockCoin> Coins = new()
    {
        Make("bitcoin", "btc", "Bitcoin", 67000, 19.7e6, 21e6),
        Make("ethereum", "eth", "Ethereum", 3300, 120.2e6, null),
        Make("tether", "usdt", "Tether", 1.0, 110e9, null, true),
        Make("binancecoin", "bnb", "BNB", 590, 147.6e6, 200e6),
        Make("solana", "sol", "Solana", 165, 460e6, null),
        Make("usd-coin", "usdc", "USDC", 1.0, 33e9, null, true),
        Make("ripple", "xrp", "XRP", 0.52, 55e9, 100e9),
        Make("dogecoin", "doge", "Dogecoin", 0.16, 145e9, null),
        Make("the-open-network", "ton", "Toncoin", 6.8, 2.5e9, null),
        Make("cardano", "ada", "Cardano", 0.45, 35.7e9, 45e9),
        Make("avalanche-2", "avax", "Avalanche", 36, 392e6, 720e6),
        Make("shiba-inu", "shib", "Shiba Inu", 0.000018, 589e12, null),
        Make("polkadot", "dot", "Polkadot", 7.2, 1.4e9, null),
        Make("chainlink", "link", "Chainlink", 14.5, 600e6, 1e9),
        Make("tron", "trx", "TRON", 0.12, 87e9, null),
        Make("bitcoin-cash", "bch", "Bitcoin Cash", 480, 19.7e6, 21e6),
        Make("near", "near", "NEAR Protocol", 6.5, 1.1e9, null),
        Make("matic-network", "matic", "Polygon", 0.7, 9.9e9, 10e9),
        Make("litecoin", "ltc", "Litecoin", 85, 74.7e6, 84e6),
        Make("uniswap", "uni", "Uniswap", 9.8, 600e6, 1e9),
        Make("internet-computer", "icp", "Internet Computer", 12, 470e6, null),
        Make("ethereum-classic", "etc", "Ethereum Classic", 27, 146e6, 210.7e6),
        Make("stellar", "xlm", "Stellar", 0.11, 29e9, 50e9),
        Make("cosmos", "atom", "Cosmos Hub", 8.1, 390e6, null),
        Make("monero", "xmr", "Monero", 160, 18.4e6, null),
        Make("filecoin", "fil", "Filecoin", 5.5, 580e6, 2e9),
        Make("aptos", "apt", "Aptos", 9, 440e6, null),
        Make("arbitrum", "arb", "Arbitrum", 1.1, 3.5e9, 10e9),
        Make("optimism", "op", "Optimism", 2.3, 1.2e9, 4.29e9),
        Make("hedera-hashgraph", "hbar", "Hedera", 0.09, 37e9, 50e9),
        Make("vechain", "vet", "VeChain", 0.03, 72.7e9, 86.7e9),
        Make("aave", "aave", "Aave", 95, 14.9e6, 16e6),
        Make("the-graph", "grt", "The Graph", 0.28, 9.5e9, 10.8e9),
        Make("algorand", "algo", "Algorand", 0.17, 8e9, 10e9),
        Make("maker", "mkr", "Maker", 2800, 920e3, null),
        Make("render-token", "rndr", "Render", 7.5, 388e6, null),
        Make("injective-protocol", "inj", "Injective", 24, 98e6, 100e6),
        Make("sui", "sui", "Sui", 1.7, 2.8e9, 10e9),
    };

    private static readonly Dictionary<string, MockCoin> ById = Coins.ToDictionary(c => c.Id);

    private static double PriceAt(MockCoin c, double t)
    {
        if (c.Stable) return c.Price * (1 + 0.0006 * Math.Sin(t / (3 * Hour) + c.S[0]));
        var m = 1 + c.Vol * (
            0.05 * Math.Sin(t / (Day * 3.1) + c.S[0]) +
            0.025 * Math.Sin(t / (Day * 0.7) + c.S[1]) +
            0.006 * Math.Sin(t / (Hour * 1.3) + c.S[2]) +
            0.0015 * Math.Sin(t / 37000 + c.S[3]) +
            0.12 * Math.Sin(t / (Day * 45) + c.S[4]));
        return c.Price * m;
    }

    private static CoinDto ToMarketItem(MockCoin c, double now)
    {
        var price = PriceAt(c, now);
        var prev = PriceAt(c, now - Day);
        double hi = price, lo = price;
        for (var i = 0; i <= 24; i++)
        {
            var p = PriceAt(c, now - i * Hour);
            if (p > hi) hi = p;
            if (p < lo) lo = p;
        }

        var r = new Rng(c.Seed);
        var spark = new List<double>(85);
        for (var i = 84; i >= 0; i--)
        {
            var noise = c.Stable ? 0 : (r.Next() - 0.5) * 0.004;
            spark.Add(PriceAt(c, now - i * 2 * Hour) * (1 + noise));
        }
        spark[^1] = price;

        var cap = price * c.Circ;
        return new CoinDto
        {
            Id = c.Id, Symbol = c.Symbol, Name = c.Name, Image = null,
            CurrentPrice = price, MarketCap = cap, MarketCapRank = 0,
            TotalVolume = cap * c.VolRatio, High24h = hi, Low24h = lo,
            PriceChangePercentage24h = (price - prev) / prev * 100,
            CirculatingSupply = c.Circ,
            TotalSupply = c.Max ?? c.Circ * 1.02,
            MaxSupply = c.Max,
            Ath = Math.Max(c.Price * c.AthMul, hi),
            Atl = Math.Min(c.Price * c.AtlMul, lo),
            SparklineIn7d = new SparklineDto { Price = spark },
        };
    }

    private static double NowMs() => DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();

    public static List<CoinDto> GetMarkets()
    {
        var now = NowMs();
        var items = Coins.Select(c => ToMarketItem(c, now)).OrderByDescending(c => c.MarketCap).ToList();
        for (var i = 0; i < items.Count; i++) items[i].MarketCapRank = i + 1;
        return items;
    }

    public static List<double[]> GetChart(string id, int days)
    {
        var now = NowMs();
        var c = ById.TryGetValue(id, out var known) ? known : Make(id, id, id, 1, 1e9, null);
        var n = days <= 1 ? 96 : days <= 7 ? 168 : 180;
        var start = now - days * Day;
        var step = (now - start) / (n - 1);
        var r = new Rng(c.Seed ^ (uint)days);
        var points = new List<double[]>(n);
        for (var i = 0; i < n; i++)
        {
            var t = start + step * i;
            var noise = c.Stable ? 0 : (r.Next() - 0.5) * 0.006;
            points.Add(new[] { Math.Round(t), PriceAt(c, t) * (1 + noise) });
        }
        points[^1] = new[] { Math.Round(now), PriceAt(c, now) };
        return points;
    }

    public static ProfileDto GetProfile(string id)
    {
        ById.TryGetValue(id, out var c);
        var name = c?.Name ?? id;
        return new ProfileDto(
            $"{name} is a digital asset traded on global crypto markets. This is demo data generated by the " +
            "Crypto Pulse mock market so the app works offline and without API rate limits. Connect the backend " +
            "to the live CoinGecko API to see the real project description, categories and links here.",
            "https://www.coingecko.com",
            new List<string> { "Cryptocurrency", c is { Stable: true } ? "Stablecoin" : "Smart Contract Platform" });
    }
}
