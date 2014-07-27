_       = require 'underscore'
mongo   = require 'mongoskin'

config  = require './config'

mongoUri = process.env.MONGOLAB_URI or process.env.MONGOHQ_URL or 'mongodb://localhost/gifs'
db = mongo.db mongoUri, {native_parser: true}
db.bind 'gif'

exports.gifs = (cb) ->
    db.gif.find().toArray (err, items) ->

        gifs = {}
        _.each items, (gif) ->
            _.each gif.tags, (tag) ->
                gif.url = "#{config.CDN_URL}/#{gif.path}"
                if gifs[tag]
                    gifs[tag].push gif
                else
                    gifs[tag] = [gif]

        cb gifs