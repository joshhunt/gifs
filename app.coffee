hbs     = require 'hbs'
logfmt  = require 'logfmt'
express = require 'express'

db      = require './database'
config  = require './config'

app = express()

hbs.registerHelper 'static', (text) ->
    prefix = if config.isProd then config config.CDN_URL else ''
    prefix + text

app.set 'views', __dirname
app.set 'view engine', 'hbs'
app.use logfmt.requestLogger()
app.use '/dist', express.static 'dist'
app.use '/static', express.static 'dist/static'

app.route '/api/gifs'
    .get (req, res) ->
        db.gifs (gifs) -> res.json {gifs}

angularRoutes = ['/', '/list']

for url in angularRoutes
    app.get url, (req, res) -> res.render 'dist/index'

port = Number process.env.PORT or 5000
app.listen port, ->
    console.log "Listening on port #{port}"