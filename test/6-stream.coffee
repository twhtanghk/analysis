_ = require 'lodash'
{stream} = require '../index'
{CandleGranularity, CoinbasePro} = require 'coinbase-pro-node'
{Writable} = require 'stream'
client = new CoinbasePro()

describe 'stream', ->
  it 'score', ->
    stream
      .score client, 'ETH-USD'
      .on 'data', (chunk) ->
         console.log "#{new Date()}: #{chunk}"
