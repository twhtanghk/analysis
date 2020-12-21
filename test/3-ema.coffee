{ohlc, ema} = require '../index'

describe 'ema', ->
  it 'ema', ->
    console.log ema (await ohlc.stock '0700.HK'), 20
