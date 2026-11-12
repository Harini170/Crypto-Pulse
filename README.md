# Crypto Pulse — mini CoinGecko-style research app

Flutter (BLoC + MVVM) client + ASP.NET Core 8 (C#) backend.

## Run it

**1. Backend** (needs .NET 8 SDK)
```bash
cd backend/CryptoPulse.Api
dotnet run
```
Swagger UI: http://localhost:3000/swagger  ·  quick check: http://localhost:3000/api/coins?per_page=3

**2. App** (needs Flutter 3.24+)
```bash
cd app
./setup.sh          # once: creates android/ios folders + enables http to the backend
flutter run
```
Windows without bash: run `flutter create . --project-name crypto_pulse --platforms android,ios`,
delete `test/widget_test.dart`, add `android:usesCleartextTraffic="true"` to `<application>` and
`<uses-permission android:name="android.permission.INTERNET"/>` in `android/app/src/main/AndroidManifest.xml`, then `flutter pub get`.

- Android emulator → backend is reached at `10.0.2.2:3000` automatically.
- Real device → `flutter run --dart-define=API_BASE_URL=http://<PC-LAN-IP>:3000/api`
- iOS simulator → `localhost` works; for plain http add `NSAllowsLocalNetworking` to Info.plist.

The backend calls the public CoinGecko API (cached 60 s). If it is rate-limited/offline it silently
switches to a built-in **mock market** whose prices move in real time; the app shows a LIVE / DEMO badge.

## Architecture (MVVM)

```
View        presentation/pages, presentation/widgets   -> pure UI, no logic
ViewModel   presentation/blocs/*                       -> BLoC: events in, immutable states out
Model       domain/ (contracts) + data/ (API, storage) -> repositories, DTOs, data sources
core/       DI (get_it), Dio client, theme, formatters, errors
```
Data flow: `Page → Bloc event → Repository → RemoteDataSource → Dio → ASP.NET API`.
Errors are normalised to `AppException` in the data layer, so blocs only emit `failure` states with a message.

```
app/lib
├── core/            constants, di, error, network, theme, utils
├── data/            models, datasources (remote + local), repositories (impl)
├── domain/          entities (sort/filter/range enums), repositories (abstract)
└── presentation/
    ├── blocs/       market · coin_detail · stats · watchlist
    ├── pages/       home (bottom-nav shell) · market · coin_detail · stats · watchlist
    └── widgets/     coin_tile, sparkline, price_chart, shimmer/empty/error views, ...
backend/CryptoPulse.Api   Program.cs, Endpoints/, Services/ (CoinGecko client, provider+cache, mock market)
```

## Requirements checklist

| Requirement | Where |
|---|---|
| Coin list, details, market stats, watchlist screens | `pages/market`, `coin_detail`, `stats`, `watchlist` |
| Price / volume / market cap / supply data | `Coin` model, detail stats grid + supply card |
| Search, filter, sort | debounced search, filter chips (All/Gainers/Losers/High volume), sort sheet — all server-side |
| Pagination | infinite scroll, 20 per page (`MarketBloc` + `/api/coins?page=&per_page=`) |
| Watchlist | `WatchlistBloc` app-wide singleton, persisted with `shared_preferences`, swipe-to-remove + undo |
| Interactive chart | `fl_chart` line chart: scrub to read exact price/time, 24H/7D/30D/90D/1Y ranges (cached per range) |
| Loading / error / empty states | shimmer skeletons, `ErrorView` with retry, `EmptyView`, snackbars for background errors |
| Live feel | 15 s silent refresh; prices flash green/red on change |
| Animation | Hero avatar, staggered list entrance, animated counters/progress/donut, page transitions |
| Backend | ASP.NET Core 8 minimal API, caching, rate-limit-safe fallback |
| Tests | `flutter test` (MarketBloc) |

## API

| Endpoint | Notes |
|---|---|
| `GET /api/coins` | `page, per_page, q, sort(market_cap\|price\|volume\|change\|name), order(asc\|desc), filter(all\|gainers\|losers\|high_volume), ids` |
| `GET /api/coins/{id}` | market data + description, categories |
| `GET /api/coins/{id}/chart?days=1\|7\|30\|90\|365` | `[[timestampMs, price], ...]` |
| `GET /api/market/stats` | totals, dominance, gainers/losers, top movers |
| `GET /api/health` | liveness |
