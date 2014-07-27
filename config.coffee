productionEnv = 'production'

module.exports =
    CDN_URL: process.env.CDN_URL or ''
    ENV: process.env.NODE_ENV
    isProd: process.env.NODE_ENV == productionEnv