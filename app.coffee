express = require 'express'
logfmt = require 'logfmt'

app = express()

app.use logfmt.requestLogger()

app.route '/'
    .get (req, res) ->
        res.send 'Hello World!'

port = Number process.env.PORT or 5000
app.listen port, ->
    console.log "Listening on port #{port}"
