enum CoinSort {
  marketCap('market_cap', 'Market cap'),
  price('price', 'Price'),
  volume('volume', '24h volume'),
  change('change', '24h change'),
  name('name', 'Name');

  const CoinSort(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

enum CoinFilter {
  all('all', 'All'),
  gainers('gainers', 'Gainers'),
  losers('losers', 'Losers'),
  highVolume('high_volume', 'High volume');

  const CoinFilter(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

enum ChartRange {
  d1(1, '24H'),
  d7(7, '7D'),
  d30(30, '30D'),
  d90(90, '90D'),
  y1(365, '1Y');

  const ChartRange(this.days, this.label);
  final int days;
  final String label;
}
