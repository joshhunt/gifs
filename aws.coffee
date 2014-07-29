crypto = require 'crypto'
config = require './config'

console.log 'Config:'
console.log config

getExpiryTime = ->
    date = new Date()
    "#{date.getFullYear()}-#{date.getMonth() + 1}-#{date.getDate() + 1}T#{date.getHours() + 3}:00:00.000Z"


createS3Policy = (contentType, callback) ->
    date = new Date()

    s3Policy =
        'expiration': getExpiryTime()
        conditions: [
            ['starts-with', '$key', 'uploads/']
            {'bucket': config.S3_BUCKET}
            {'acl': 'public-read'}
            ['starts-with', '$Content-Type', contentType]
            {'success_action_status' : '201'}
        ]

    stringPolicy = JSON.stringify s3Policy
    base64Policy = new Buffer(stringPolicy, 'utf-8').toString 'base64'
    signature = crypto.createHmac('sha1', config.S3_SECRET).update(base64Policy).digest('base64')
    s3Credentials = {
        s3Policy: base64Policy
        s3Signature: signature
        AWSAccessKeyId: config.S3_KEY
    }

    callback s3Credentials


exports.getS3Policy = (req, res) ->
    createS3Policy req.query.mimeType, (creds, err) ->
        res.send 200, creds  unless err
        res.send 200, err    if err
