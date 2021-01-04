# analysis
Price data analysis

## Install
```
npm install https://github.com/twhtanghk/analysis
```

## Usage
### symbol conversion between yahoo and aastock
```
{symbol} = require 'analysis'

console.log symbol.yahoo '00700'
console.log symbol.aastock '0700.HK'
```
```
0700.HK
00700
```

### get stock or crypto currency ohlc data 
```
{ohlc} = require '../index'

do ->
  console.log await ohlc.stock '0700.HK'
  console.log await ohlc.cryptoCurr 'WETH'
```
```
[
  {
    date: 1608538127,
    open: 580.5,
    high: 580.5,
    low: 571,
    close: 572,
    volume: 13157070,
    adjclose: 572
  },
  {
    date: 1608255000,
    open: 586,
    high: 586,
    low: 574.5,
    close: 580,
    volume: 19205790,
    adjclose: 580
  },
  ... 146 more items
]
[
  {
    date: 1608508800,
    open: 638.3909316243046,
    high: 638.3909316243046,
    low: 610.2490286010485,
    close: 610.2490286010485,
    volume: '231079949.274202194832119654439809'
  },
  {
    date: 1608422400,
    open: 658.9972243614757,
    high: 658.9972243614757,
    low: 638.3909316243046,
    close: 638.3909316243046,
    volume: '296423267.6780013559889601124249129'
  },
  ... 128 more items
]
```

### ema(days) of input data
```
{ema, ohlc} = require 'analysis'

do ->
  console.log await ema (await ohlc.stock '0700.HK'), 20
```
```
[
  { date: 1596072600, ema: 533.341520782937 },
  { date: 1595986200, ema: 531.9280426131335 },
  ...
]
```

### get close/ema20, ema20/ema60, ema60/ema120 of specified stock
```
{ohlc, indicators} = require 'analysis'

do ->
  console.log indicators await ohlc.stock '0700.HK'
```
```
{
  'c/s': 0.9889439919923563,
  's/m': 1.0127551000484996,
  'm/l': 1.0386915913754522
}
```

### get peers stock of input symbol
```
{peers} = require '../index'

do ->
  console.log await peers '700'
```
```
[
  '0082', '0136', '0250', '0302', '0327', '0395',
  ...
]
```

### get percentage of stocks its closing price higher than EMA20 
```
{percentMA20} = require 'analysis'

do ->
  console.log await percentMA20 await peers.list '700'
```
```
{
  '1596556800000': 51.5625,
  '1596470400000': 50,
  ...
}
```

### get market breadth for the peers of input stock
```
{breadth} = require 'analysis'

do ->
  console.log await breadth '700'
```
```
{
  '1596556800000': 51.5625,
  '1596470400000': 50,
  ...
}
```
