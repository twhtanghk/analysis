{browser, Peers} = require 'aastocks'
{breadth} = require '../index'

describe 'breadth', ->
  it 'breadth', ->
    console.log await breadth '700'
