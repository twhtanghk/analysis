_ = require 'lodash'
Promise = require 'bluebird'
{Readable} = require 'stream'
{getHistoricalPrices} = require 'yahoo-stock-api'
moment = require 'moment'
{PublicClient} = require 'coinbase-pro-node-api'
client = new PublicClient()
url = 'https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v2'
needle = require 'needle'
{EMA} = require 'technicalindicators'
{CandleGranularity, ProductEvent} = require 'coinbase-pro-node'

module.exports =
  pattern:
    aastock: /^0*([0-9]+)$/
    yahoo: /^0*([0-9]+)\.HK$/

  symbol: 
    yahoo: (code) ->
      {aastock, yahoo} = module.exports.pattern
      ret = code
      if aastock.test code
        ret = (code.match aastock)[1]
          .padStart 4, '0'
          .concat '.HK'
      ret
    aastock: (code) ->
      {aastock, yahoo} = module.exports.pattern
      ret = code    
      if yahoo.test code
        ret = (code.match yahoo)[1]
          .padStart 5, '0'
      ret

  unpack: (rows, key) ->
    rows.map (row) ->
      row[key]

  ema: (rows, period) ->
    rows = _.orderBy rows, ['date'], ['desc']
    values = module.exports.unpack rows, 'close'
    x = module.exports.unpack(rows, 'date')
    y = EMA.calculate {period, values}
    x.map (date, i) ->
      date: date
      ema: y[i]

  indicators: (rows) ->
    # filter invalid data
    rows = rows.filter ({close}) ->
      close?
    max = _.maxBy(rows, 'high').high
    min = _.minBy(rows, 'low').low
    close = _.maxBy(rows, 'date').close
    open = _.minBy(rows, 'date').open
    ema = [
      module.exports.ema rows, 20
      module.exports.ema rows, 60
      module.exports.ema rows, 120
    ]
    'c/s': (close - ema[0][0].ema) / ema[0][0].ema * 100
    's/m': (ema[0][0].ema - ema[1][0].ema) / ema[1][0].ema * 100
    'm/l': (ema[1][0].ema - ema[2][0].ema) / ema[2][0].ema * 100
    'max': max
    'min': min
    'close': close
    'ema20': ema[0][0].ema
    'ema60': ema[1][0].ema
    'ema120': ema[2][0].ema
    'open': open
    'diff': 
      'up': (max - close) / close * 100
      'down': (close - min) / close * 100
    'date':
      'start': _.minBy(rows, 'date').date
      'end': _.maxBy(rows, 'date').date

  # convert [{date: date1, k1: v1, ..} ...] 
  # to {date: {date: date1, k1: v1, ...}, ...}
  # with date reset its time to midnight
  dateOnly: (rows) ->
    ret = {}
    for row in rows
      k = moment new Date row.date * 1000
        .set 'hour', 0
        .set 'minute', 0
        .set 'second', 0
        .set 'millisecond', 0
        .toDate()
        .getTime()
      ret[k] = row
    ret

  breadth: (symbols, days=180) ->
    ret = {}
    for symbol in symbols
      try
        data = await module.exports.ohlc.stock symbol, days
        map = module.exports.dateOnly data
        for date, row of module.exports.dateOnly module.exports.ema data, 20
          if not ret[date]?
            ret[date] = {}
          ret[date][symbol] = 
            ema: row.ema
            close: map[date]?.close
      catch e
        console.error "error in loading #{symbol} data"
    for date, set of ret
      overEMA = 0
      length = (symbol for symbol, {ema, close} of set).length
      for symbol, {ema, close} of set
        if close >= ema
          overEMA++
      ret[date] = overEMA / length * 100
    for date, percent of ret
      date: new Date parseInt date
      percent: percent
          
  peers: (peerSymbol) ->
    client = require 'mqtt'
      .connect process.env.MQTTURL,
        username: process.env.MQTTUSER
        clientId: process.env.MQTTCLIENT
        clean: false
    ret = new Promise (resolve, reject) ->
      client
        .on 'connect', ->
          client.subscribe 'stock/aastocks/peers', qos: 2
        .on 'message', (topic, msg) ->
          if topic == 'stock/aastocks/peers'
            {peers} = JSON.parse msg.toString()
            resolve peers
        .publish 'stock/peers', peerSymbol
    await ret
      .timeout 5000
      .finally ->
        client.end()
    
  graphQL: (query) ->
    await needle 'post', url, {query}, json: true
    
  ohlc:
    stock: (symbol, days=365) ->
      symbol = module.exports.symbol.yahoo symbol
      start = moment()
        .subtract days, 'days'
        .toDate()
      {error, currency, response} = await getHistoricalPrices start, new Date(), symbol, '1d'
      if error
        throw error
      response.filter (row) ->
        not row.type

    ###
    opts:
      product_id: (default BTC-USD)
      granularity: (optional with default 300s)
      start: start time in ISO string format (optional with default 120 historical data)
      end: start time in ISO string format (optional with default now))
    ###
    cryptoCurr: (opts = {}) ->
      _.defaults opts,
        granularity: 300 # default 300s if not defined
      end = moment()
      start = moment.unix(end.unix() - opts.granularity * 120)
      _.defaults opts,
        end: end.toISOString()
        start: start.toISOString()
      (await client.getHistoricRates opts)
        .map ([time, low, high, open, close, volume]) ->
          date: time
          low: low
          high: high
          open: open
          close: close
          volume: volume

  stream:
    candle: (client, product='ETH-USD', granularity=CandleGranularity.ONE_MINUTE, n=1) ->
      end = moment()
      start = moment().subtract n * granularity, 'seconds'
      rows = (await client.rest.product.getCandles product, { granularity, start, end }).map (row) ->
        _.extend row, date: row.openTimeInMillis / 1000
      latestOpen = rows[rows.length - 1].openTimeInISO
      client.rest.product.watchCandles product, granularity, latestOpen
      new Readable
        objectMode: true
        construct: ->
          rows.map (row) => @push row
          client.rest
            .on ProductEvent.NEW_CANDLE, (product, currGranularity, data) =>
              if granularity == currGranularity
                @push _.extend(data, date: data.openTimeInMillis / 1000)
    
    indicators: (client, product='ETH-USD', granularity=CandleGranularity.ONE_MINUTE) ->
      new Readable
        objectMode: true
        read: -> @pause()
        construct: ->
          rows = []
          (await module.exports.stream.candle client, product, granularity, 120)
            .on 'data', (data) =>
              rows.push data
              if rows.length >= 120
                @push module.exports.indicators rows
                @resume()
                rows = rows[-120..]
