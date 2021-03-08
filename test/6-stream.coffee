{stream} = require '../index'
{CoinbasePro} = require 'coinbase-pro-node'
{Writable} = require 'stream'
client = new CoinbasePro()

describe 'stream', ->
  it 'indicators', ->
    (await stream.indicators client)
      .pipe new Writable objectMode: true, write: (data, encoding, cb) -> 
        process.stdout.write JSON.stringify(data, null, 2), encoding, cb
