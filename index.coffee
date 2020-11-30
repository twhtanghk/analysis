{getHistoricalPrices} = require 'yahoo-stock-api'
moment = require 'moment'
url = 'https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v2'
needle = require 'needle'
{EMA} = require 'technicalindicators'

module.exports =
  unpack: (rows, key) ->
    rows.map (row) ->
      row[key]

  ema: (rows, period) ->
    values = module.exports.unpack rows, 'close'
    x = module.exports.unpack rows, 'date'
      .slice 0, rows.length - period + 1
    y = EMA.calculate {period, values}
    {x, y}

  indicators: (rows) ->
    ema =
      20: module.exports.ema rows, 20
      60: module.exports.ema rows, 60
      120: module.exports.ema rows, 120
    'c/s': rows[0].close / ema[20].y[0]
    's/m': ema[20].y[0] / ema[60].y[0]
    'm/l': ema[60].y[0] / ema[120].y[0]

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