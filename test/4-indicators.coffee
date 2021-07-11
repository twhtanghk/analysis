{ohlc, indicators} = require '../index'

describe 'indicators', ->
  it '7200 tencent', ->
    console.log indicators await ohlc.stock '0043.HK'

###
  it 'eth-btc', ->
    for i in [60, 300, 900, 3600, 21600, 86400]
      console.log indicators await ohlc.cryptoCurr product_id: 'ETH-USDC', granularity: i
###
