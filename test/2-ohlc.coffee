{ohlc} = require '../index'

describe 'ohlc', ->
  it 'stock', ->
    console.log await ohlc.stock '0700.HK'

  it 'cryptoCurr', ->
    console.log await ohlc.cryptoCurr 'WETH'
