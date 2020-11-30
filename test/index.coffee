{ohlc, ema, indicators} = require '../index'
do ->
  console.log indicators (await ohlc.stock '0388.HK')
