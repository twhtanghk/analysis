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
    ema = [
      module.exports.ema rows, 20 - 1
      module.exports.ema rows, 60 - 1
      module.exports.ema rows, 120 - 1
    ]
    'c/s': rows[0].close / ema[0][0].ema
    's/m': ema[0][0].ema / ema[1][0].ema
    'm/l': ema[1][0].ema / ema[2][0].ema

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

  percentMA20: (symbols, days=180) ->
    ret = {}
    for symbol in symbols
      data = await module.exports.ohlc.stock symbol, days
      map = module.exports.dateOnly data
      for date, row of module.exports.dateOnly module.exports.ema data, 20
        if not ret[date]?
          ret[date] = {}
        ret[date][symbol] = 
          ema: row.ema
          close: map[date]?.close
    for date, set of ret
      overEMA = 0
      for symbol, {ema, close} of set
        if close >= ema
          overEMA++
      ret[date] = overEMA / symbols.length * 100
    ret
          
  breadth: (peerSymbol) ->
    try
      {browser, Peers} = require 'aastocks'
      peers = new Peers browser: await browser()
      symbols = await peers.list peerSymbol
      symbols: symbols
      breadth: await module.exports.percentMA20 symbols
    finally
      peers.browser.close()

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
