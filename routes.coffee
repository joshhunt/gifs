_      = require 'underscore'
crypto = require 'crypto'

db     = require './database'
config = require './config'


getExpiryTime = ->
    date = new Date()
    "#{date.getFullYear()}-#{date.getMonth() + 1}-#{date.getDate() + 1}T#{date.getHours() + 3}:00:00.000Z"

createS3Policy = (contentType, callback) ->
    date = new Date()
    bucket = config.S3_BUCKET
    acl = 'public-read'

    s3Policy =
        'expiration': getExpiryTime()
        conditions: [
            ['starts-with', '$key', 'uploads/']
            {bucket}
            {acl}
            ['starts-with', '$Content-Type', contentType]
            {'success_action_status' : '201'}
        ]

    stringPolicy = JSON.stringify s3Policy
    base64Policy = new Buffer(stringPolicy, 'utf-8').toString 'base64'
    signature = crypto.createHmac('sha1', config.S3_SECRET).update(base64Policy).digest('base64')
    s3Credentials = {
        policy: base64Policy
        signature: signature
        AWSAccessKeyId: config.S3_KEY
        endpoint: "https://#{bucket}.s3.amazonaws.com/"
        acl: acl
    }
    callback s3Credentials


@getS3Policy = (req, res) ->
    createS3Policy req.query.mimeType, (creds, err) ->
        res.status(200).send(creds)  unless err
        res.status(500).send(err)    if err

@getAllGifs = (req, res) ->
    db.gifs (gifs) ->
        res.json {gifs}

@createGif = (req, res) ->
    res.status(400).json({error: 'Missing body'}) unless req.body

    console.log 'request body:'
    console.log req.body

    # Pick only whitelisted keys
    newGif = _.pick req.body, ['title', 'path', 'tags']
    newGif.tags ?= ['@not-tagged']

    console.log 'gonna create a gif'
    db.createGif newGif, (gif, err) ->
        if err
            console.log 'fuck, an error', err
            res.status(500).json err
        console.log '\ncreateGif route callback got called, about to respond with'
        console.log gif
        res.status(201).json gif


