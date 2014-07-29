fs         = require 'fs'
url        = require 'url'

hbs        = require 'hbs'
logfmt     = require 'logfmt'
express    = require 'express'
bodyParser = require 'body-parser'

config     = require './config'
routes     = require './routes'

app = express()

hbs.registerHelper 'static', (text) ->
    fsPath = 'dist' + text
    fsPath = url.parse(fsPath).pathname
    if fs.existsSync fsPath
        console.log fsPath, 'exists on the file system'
    else
        console.log fsPath, 'DOESNT exist on the file system'

    prefix = if config.isProd then config.CDN_URL else ''
    prefix + text

app.set 'views', __dirname
app.set 'view engine', 'hbs'

app.use bodyParser.json()
app.use logfmt.requestLogger()
app.use '/dist', express.static 'dist'
app.use '/static', express.static 'dist/static'

app.route '/api/gifs'
    .get  routes.getAllGifs
    .post routes.createGif

app.get '/api/sign', routes.getS3Policy

angularRoutes = ['/', '/list']

for route in angularRoutes
    app.get route, (req, res) -> res.render 'dist/index'

port = Number process.env.PORT or 5000
app.listen port, -> console.log "Listening on port #{port}"