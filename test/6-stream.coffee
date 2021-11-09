_ = require 'lodash'
{stream} = require '../index'
{CandleGranularity, CoinbasePro} = require 'coinbase-pro-node'
{Writable} = require 'stream'
client = new CoinbasePro()

describe 'stream', ->
  it 'score', ->
    [
      'BTC-USD'
      'ETH-USD'
    ].map (product) ->
      stream
        .score client, product
        .on 'data', (chunk) ->
          console.log "#{new Date()}: #{product} #{chunk}"
