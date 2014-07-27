express = require 'express'
logfmt = require 'logfmt'

app = express()

app.use logfmt.requestLogger()

app.use '/dist', express.static 'dist'
app.use '/static', express.static 'dist/static'

app.route '/api'
    .get (req, res) ->
        res.send 'Hello World!'

angularRoutes = ['/', '/list']

for url in angularRoutes
    app.get url, (req, res) -> res.sendfile './dist/index.html'

port = Number process.env.PORT or 5000
app.listen port, ->
    console.log "Listening on port #{port}"
