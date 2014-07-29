_       = require 'underscore'
mongo   = require 'mongoskin'

config  = require './config'

mongoUri = process.env.MONGOLAB_URI or process.env.MONGOHQ_URL or 'mongodb://localhost/gifs'
db = mongo.db mongoUri, {native_parser: true}
db.bind 'gif'

marshelGif = (gif) ->
    console.log 'marshelling gif with path', gif.path
    gif.url = "#{config.CDN_URL}/#{gif.path}"
    gif

@gifs = (cb) ->
    db.gif.find().toArray (err, items) ->

        gifs = {}
        _.each items, (gif) ->
            marshelGif gif
            _.each gif.tags, (tag) ->
                if gifs[tag]
                    gifs[tag].push gif
                else
                    gifs[tag] = [gif]

        cb gifs

@createGif = (newGif, cb) ->
    console.log 'db.createGif...'
    db.gif.insert newGif, (err, result) ->
        console.log 'cool, inserting gif returned'

        if err
            console.log 'fuck, there was an error!'
            console.log err
            cb result, err

        console.log 'and with no errors! Here\'s the proper gif:'
        console.log result
        gif = marshelGif result[0]
        console.log gif
        cb gif, null
