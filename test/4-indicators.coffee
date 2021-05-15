{ohlc, indicators} = require '../index'

describe 'indicators', ->
  it '700 tencent', ->
    console.log indicators await ohlc.stock '0700.HK'

  it 'eth-btc', ->
    for i in [60, 300, 900, 3600, 21600, 86400]
      console.log indicators await ohlc.cryptoCurr product_id: 'ETH-USDC', granularity: i
