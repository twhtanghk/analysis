_ = require 'lodash'
Promise = require 'bluebird'
{getHistoricalPrices} = require 'yahoo-stock-api'
moment = require 'moment'
url = 'https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v2'
needle = require 'needle'
{EMA} = require 'technicalindicators'

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
    values = module.exports.unpack rows, 'close'
    x = module.exports.unpack rows, 'date'
      .slice 0, rows.length - period + 1
    y = EMA.calculate {period, values}
    x.map (date, i) ->
      date: date
      ema: y[i]

  indicators: (rows) ->
    max = _.maxBy(rows, 'high').high
    min = _.minBy(rows, 'low').low
    close = _.maxBy(rows, 'date').close
    open = _.minBy(rows, 'date').open
    ema = [
      module.exports.ema rows, 20 - 1
      module.exports.ema rows, 60 - 1
      module.exports.ema rows, 120 - 1
    ]
    'c/s': rows[0].close / ema[0][0].ema
    's/m': ema[0][0].ema / ema[1][0].ema
    'm/l': ema[1][0].ema / ema[2][0].ema
    'max': max
    'min': min
    'close': close
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

    cryptoCurr: (symbol, days=365) ->
      {id} = (await module.exports.graphQL "{tokens (first: 1, orderDirection: desc, orderBy: tradeVolume, where: {name: \"#{symbol}\"}) { id symbol name tradeVolume }}")
        .body.data.tokens[0]
      data = (await module.exports.graphQL "{tokenDayDatas (first: #{days}, orderBy: date, orderDirection: desc, where:{token: \"#{id}\"}){ id date priceUSD dailyVolumeUSD } }")
        .body.data.tokenDayDatas
        .map ({date, dailyVolumeUSD, priceUSD}) ->
          {date, price: priceUSD, volume: dailyVolumeUSD}
      curr = data[0]
      data[1..].map ({date, price, volume}) ->
        ret = 
          date: curr.date
          open: parseFloat price
          high: Math.max price, curr.price
          low: Math.min price, curr.price
          close: parseFloat curr.price
          volume: curr.volume
        curr = {date, price, volume}
        ret
