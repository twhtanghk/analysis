client = require '../finnhub'

describe "finnhub", ->

 it 'peers', ->
   console.log await client.companyPeersAsync 'AAPL'

 it 'stock ohlc', ->
   console.log await client.stockOhlc
     symbol: 'IBM'
     resolution: 'D'
     from: new Date 1572651390 * 1000
     to: new Date 1575243390 * 1000
