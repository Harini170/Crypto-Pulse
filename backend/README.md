# Crypto Pulse API (ASP.NET Core 8)

```bash
cd CryptoPulse.Api
dotnet run                       # live CoinGecko data, auto-fallback to mock
Market__UseMock=true dotnet run  # force the offline mock market (PowerShell: $env:Market__UseMock="true"; dotnet run)
```
Listens on `http://0.0.0.0:3000` (override with `ASPNETCORE_URLS`).
Optional CoinGecko demo key: `Market__CoinGeckoApiKey=...`.

Swagger UI: http://localhost:3000/swagger (also opens from http://localhost:3000/).
