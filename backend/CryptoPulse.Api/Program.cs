using CryptoPulse.Api.Endpoints;
using CryptoPulse.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// Listen on all interfaces so the Android emulator (10.0.2.2) and real devices can reach us.
var urls = Environment.GetEnvironmentVariable("ASPNETCORE_URLS") ?? "http://0.0.0.0:3000";
builder.WebHost.UseUrls(urls);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(o => o.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
{
    Title = "Crypto Pulse API",
    Version = "v1",
    Description = "CoinGecko-style market data (live CoinGecko with automatic mock fallback).",
}));
builder.Services.AddMemoryCache();
builder.Services.AddHttpClient<CoinGeckoClient>();
builder.Services.AddSingleton<IMarketProvider, MarketProvider>();
builder.Services.AddCors(o => o.AddDefaultPolicy(p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

var app = builder.Build();

app.UseExceptionHandler(b => b.Run(async ctx =>
{
    ctx.Response.StatusCode = StatusCodes.Status500InternalServerError;
    await ctx.Response.WriteAsJsonAsync(new { message = "Internal server error" });
}));
app.UseCors();

// Swagger is enabled in every environment (this is a demo / assessment API).
app.UseSwagger();
app.UseSwaggerUI(o =>
{
    o.SwaggerEndpoint("/swagger/v1/swagger.json", "Crypto Pulse API v1");
    o.DocumentTitle = "Crypto Pulse API";
});
app.Use(async (ctx, next) =>
{
    app.Logger.LogInformation("{Method} {Path}{Query}", ctx.Request.Method, ctx.Request.Path, ctx.Request.QueryString);
    await next();
});

app.MapGet("/", () => Results.Redirect("/swagger")).ExcludeFromDescription();
app.MapCryptoEndpoints();
app.MapFallback(() => Results.NotFound(new { message = "Route not found" }));

var mode = app.Configuration.GetValue<bool>("Market:UseMock") ? "MOCK" : "LIVE (auto-fallback to mock)";
app.Logger.LogInformation("Crypto Pulse API [{Mode}] on {Urls}", mode, urls);
app.Run();
