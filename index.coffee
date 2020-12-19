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
      pattern = if aastock.test code then aastock else yahoo
      (code.match pattern)[1]
        .padStart 4, '0'
        .concat '.HK'
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
    {x, y}

  indicators: (symbol) ->
    if Array.isArray symbol
      for s in symbol
        await module.exports.indicators s
    else
      symbol = module.exports.symbol.yahoo symbol
      data = await module.exports.ohlc.stock symbol, 180
      ema =
        20: module.exports.ema data, 20
        60: module.exports.ema data, 60
        120: module.exports.ema data, 120
      'c/s': data[0].close / ema[20].y[0]
      's/m': ema[20].y[0] / ema[60].y[0]
      'm/l': ema[60].y[0] / ema[120].y[0]

  percentMA20: (stocks) ->
    overMA20 = 0
    for symbol in stocks
      indicators = await module.exports.indicators symbol
      if indicators['c/s'] > 1
        overMA20++
    overMA20 / stocks.length * 100

  graphQL: (query) ->
    await needle 'post', url, {query}, json: true
    
  ohlc:
    stock: (symbol, days=365) ->
      start = moment()
        .subtract days, 'days'
        .toDate()
      {error, currency, response} = await getHistoricalPrices start, new Date(), symbol, '1d'
      if error
        throw error
      response.filter (row) ->
        not row.type

    cryptoCurr: (symbol, days=365) ->
      {id} = (await module.exports.graphQL "{tokens (first: 1, orderDirection: desc, orderBy: tradeVolume, where: {symbol: \"#{symbol}\"}) { id symbol name tradeVolume }}")
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
