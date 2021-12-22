{symbol} = require '../index.coffee'

describe "symbol", ->

 it 'parse', ->
   console.log symbol.parse '5'
   console.log symbol.parse '5.hk'
   console.log symbol.parse '002466.sz 天齐锂业'

 it 'yahoo', ->
   console.log symbol.yahoo '00700'

 it 'aastock', ->
   console.log symbol.aastock '0700.HK'

 it 'unknown', ->
   console.log symbol.yahoo '^HSI'
