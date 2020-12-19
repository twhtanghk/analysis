{browser, Industry} = require 'aastocks'
{percentMA20} = require '../index'

do ->
  industry = new Industry browser: await browser()
  for name, href of await industry.list()
    try
      stocks = await industry.constituent href
      console.log name
      console.log await percentMA20 stocks
    catch err
      console.error err
