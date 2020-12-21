{browser, Peers} = require 'aastocks'
{percentMA20} = require '../index'

describe 'percentMA20', ->
  it 'percentMA20', ->
    peers = new Peers browser: await browser()
    console.log await percentMA20 await peers.list '700'
    peers.browser.close()
