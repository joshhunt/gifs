hbs     = require 'hbs'
logfmt  = require 'logfmt'
express = require 'express'

app = express()
config =
    CDN_URL: process.env.CDN_URL or ''


hbs.registerHelper 'static', (text) ->
    config.CDN_URL + text

app.use logfmt.requestLogger()
app.use '/dist', express.static 'dist'
app.use '/static', express.static 'dist/static'
app.set 'view engine', 'hbs'
app.set 'views', __dirname

app.route '/api'
    .get (req, res) ->
        res.send 'Hello World!'

app.route '/api/gifs'
    .get (req, res) ->
        console.log 'Getting gifs'
        res.json require './tmp/gifs.json'

angularRoutes = ['/', '/list']

for url in angularRoutes
    app.get url, (req, res) -> res.render 'dist/index'

port = Number process.env.PORT or 5000
app.listen port, ->
    console.log "Listening on port #{port}"