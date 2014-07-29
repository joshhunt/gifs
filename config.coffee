productionEnv = 'production'

env = (key) -> process.env[key] or ''

module.exports =
    CDN_URL:   env 'CDN_URL'
    S3_BUCKET: env 'S3_BUCKET'
    S3_KEY:    env 'S3_KEY'
    S3_SECRET: env 'S3_SECRET'
    ENV:       env 'NODE_ENV'
    isProd:    env('NODE_ENV') == productionEnv