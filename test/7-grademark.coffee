{ohlc, dataForgeIndicators, strategy} = require '../index'

describe 'grademark', ->
  rows = null

  it 'ohlc data', ->
    rows = await ohlc.stock '7200', 365
    console.log rows

  it 'data forge indicators', ->
    rows = dataForgeIndicators.validate rows
    rows = dataForgeIndicators.ema rows
    rows = dataForgeIndicators.rsi rows
    rows = dataForgeIndicators.streaks rows, 3
    console.log rows.toJSON()

  it 'backtest', ->
    {backtest, analyze} = require 'grademark'
    rows = rows.renameSeries date: 'time'
    console.log rows.toJSON()
    trades = backtest strategy.rsiThree(), rows  
    analysis = analyze 100000, trades
    console.log trades
    console.log analysis
