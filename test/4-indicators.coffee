{ohlc, indicators} = require '../index'

describe 'indicators', ->
  it 'indicators', ->
    console.log indicators await ohlc.stock '0700.HK'
