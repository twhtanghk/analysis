_ = require 'lodash'
{stream} = require '../index'
{CandleGranularity, CoinbasePro} = require 'coinbase-pro-node'
{Writable} = require 'stream'
client = new CoinbasePro()

describe 'stream', ->
###
  it 'indicators', ->
    (await stream.indicators client)
      .pipe new Writable objectMode: true, write: (data, encoding, cb) -> 
        console.log JSON.stringify(data, null, 2)
        cb()
###

  it 'granularity', ->
    granularity = [
      'ONE_MINUTE'
      'FIVE_MINUTES'
      'FIFTEEN_MINUTES'
      'ONE_HOUR'
      'SIX_HOURS'
      'ONE_DAY'
    ]
    res = granularity.reduce (res, k) -> 
      res[k] = {}
      res
    , {}
    # count positive or negative value of c/s, s/m, m/l for 1, 5, 15 min, 1 hr
    score = (data) ->
      min = [0..3].map (i) -> data[granularity[i]]
      _.sumBy min, (d) ->
         Math.sign(d['c/s']) + Math.sign(d['s/m']) + Math.sign(d['m/l'])
    granularity.map (i) ->
      (await stream.indicators client, 'ETH-USD', CandleGranularity[i])
        .pipe new Writable objectMode: true, write: (data, encoding, cb) ->
          res[i] = data
          console.log JSON.stringify res, null, 2
          console.log "#{new Date()}: #{score res}"
          cb()
