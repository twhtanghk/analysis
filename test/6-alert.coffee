{alert} = require '../index'
{CoinbasePro} = require 'coinbase-pro-node'

describe 'alert', ->
  it 'alert', ->
    {rest} = new CoinbasePro()
    console.log alert rest
