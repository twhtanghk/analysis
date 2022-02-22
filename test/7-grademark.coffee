{ohlc, dataForgeIndicators, strategy} = require '../index'

describe 'grademark', ->
  rows = null

  it 'ohlc data', ->
    rows = await ohlc.stock '7200'
    console.log rows

  it 'data forge indicators', ->
    rows = dataForgeIndicators rows
    console.log rows.toJSON()

  it 'backtest', ->
    {backtest, analyze} = require 'grademark'
    rows = rows.renameSeries date: 'time'
    console.log rows.toJSON()
    trades = backtest strategy.movAverage(), rows  
    analysis = analyze 100000, trades
    console.log trades
    console.log analysis
