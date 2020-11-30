{ohlc, ema, indicators} = require '../index'
do ->
  ret = {}
  for symbol in ['0388.HK', '9988.HK']
    ret[symbol] = await ohlc.stock symbol
  console.log indicators ret
