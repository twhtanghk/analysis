Promise = require 'bluebird'
finnhub = require 'finnhub'
key = finnhub.ApiClient.instance.authentications['api_key']
key.apiKey = process.env.APIKEY
client = Promise.promisifyAll new finnhub.DefaultApi()

# resolution: 1, 5, 15, 30, 60, D, W, M
# from and to: Date
client.stockOhlc = ({symbol, resolution, from, to}) ->
  from = Math.round from.getTime() / 1000
  to = Math.round to.getTime() /1000
  {o, h, l, c, t, v} = await client.stockCandlesAsync symbol, resolution, from, to
  o.map (v, i) ->
    open: o[i]
    high: h[i]
    low: l[i]
    close: c[i]
    volume: v[i]
    date: new Date t[i] * 1000

module.exports = client
