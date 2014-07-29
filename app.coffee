hbs     = require 'hbs'
logfmt  = require 'logfmt'
express = require 'express'

db      = require './database'
config  = require './config'
aws     = require './aws'

app = express()

hbs.registerHelper 'static', (text) ->
    prefix = if config.isProd then config.CDN_URL else ''
    prefix + text

app.set 'views', __dirname
app.set 'view engine', 'hbs'
app.use logfmt.requestLogger()
app.use '/dist', express.static 'dist'
app.use '/static', express.static 'dist/static'

app.get '/api/gifs', (req, res) ->
    db.gifs (gifs) -> res.json {gifs}

app.get '/api/sign', aws.getS3Policy

angularRoutes = ['/', '/list']

for url in angularRoutes
    app.get url, (req, res) -> res.render 'dist/index'

port = Number process.env.PORT or 5000
app.listen port, ->
    console.log "Listening on port #{port}"