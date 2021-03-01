{alert} = require '../index'
{CoinbasePro} = require 'coinbase-pro-node'
{Writable} = require 'stream'

describe 'alert', ->
  it 'alert', ->
    {rest} = new CoinbasePro()
    (await alert rest)
      .pipe new Writable objectMode: true, write: (data, encoding, cb) -> 
        process.stdout.write JSON.stringify(data, null, 2), encoding, cb
