{symbol} = require '../index.coffee'

describe "symbol", ->

 it 'yahoo', ->
   console.log symbol.yahoo '00700'

 it 'aastock', ->
   console.log symbol.aastock '0700.HK'

 it 'unknown', ->
   console.log symbol.yahoo '^HSI'
