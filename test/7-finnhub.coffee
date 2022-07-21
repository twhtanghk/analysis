Promise = require 'bluebird'
moment = require 'moment'
client = require '../finnhub'
{dataBreadth} = require '../index'

describe "finnhub", ->

 it 'peers', ->
   console.log await client.companyPeersAsync 'IBM'

 it 'stock ohlc', ->
   from = moment()
   to = from.toDate()
   from = from
     .subtract 60 * 24, 'm'
     .toDate()
   console.log await client.stockOhlc
     symbol: 'AAPL'
     resolution: '60'
     from: from
     to: to

 it 'breadth', ->
   resolution = 'D'
   range = 120
   from = moment()
   to = from.toDate()
   switch resolution
     when '1', '5', '15', '30', '60'
       from = from
         .subtract parseInt(resolution) * range, 'm'
         .toDate()
     when 'D'
       from = from
         .subtract range, 'd'
         .toDate()
     when 'W'
       from = from
         .subtract range, 'w'
         .toDate()
     when 'M'
       from = from
         .subtract range, 'M'
         .toDate()
   list = await Promise.all (await client.companyPeersAsync 'TSLA')
     .map (symbol) ->
       symbol: symbol
       data: await client.stockOhlc {symbol, resolution, from, to}
   console.log dataBreadth list
