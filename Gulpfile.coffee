require 'colors'
es            = require 'event-stream'
gulp          = require 'gulp'
gutil         = require 'gulp-util'
order         = require 'gulp-order'
stylus        = require 'gulp-stylus'
rimraf        = require 'rimraf'
coffee        = require 'gulp-coffee'
rename        = require 'gulp-rename'
concat        = require 'gulp-concat'
uglifyjs      = require 'gulp-uglify'
minifycss     = require 'gulp-minify-css'
bowerFiles    = require 'main-bower-files'
awspublish    = require 'gulp-awspublish'
ngAnnotate    = require 'gulp-ng-annotate'
ngTemplates   = require 'gulp-angular-templatecache'
autoprefiexer = require 'gulp-autoprefixer'

OUTPUT = './dist'
env = process.env

gulp.on 'err', gutil.log

gulp.task 'clean', (cb) -> rimraf OUTPUT, cb

gulp.task 'styles', ->
    dest = "#{OUTPUT}/static/"
    gulp.src './frontend/styles/_main.styl'
        .pipe stylus()
        .pipe autoprefiexer()
        .pipe rename 'styles.css'
        .pipe gulp.dest dest
        .pipe minifycss()
        .pipe rename {suffix: '.min'}
        .pipe gulp.dest dest

gulp.task 'scripts', ->
    dest = "#{OUTPUT}/static/"

    dependancies = gulp.src bowerFiles()
        .pipe concat 'dependancies.js'

    templates = gulp.src './frontend/templates/**/*.html'
        .pipe ngTemplates 'templates.js', {module: 'gifs-templates', standalone: true}

    app = gulp.src './frontend/scripts/**/*.coffee'
        .pipe coffee()
        .pipe concat 'app.js'

    es.merge dependancies, templates, app
        .pipe order ['dependancies.js', 'templates.js', 'app.js']
        .pipe concat 'bundle.js'
        .pipe gulp.dest dest
        .pipe uglifyjs()
        .pipe rename {suffix: '.min'}
        .pipe gulp.dest dest

gulp.task 'assets', ->
    gulp.src './frontend/assets/**'
        .pipe gulp.dest OUTPUT

gulp.task 'watch', ->
    gutil.log 'Watching files: will rebuild on file changes'.blue
    gulp.watch './frontend/assets/**', ['assets']
    gulp.watch './frontend/styles/**', ['styles']
    gulp.watch './frontend/scripts/**/*.coffee', ['scripts']
    gulp.watch './frontend/templates/**/*.html', ['scripts']

gulp.task 'publish', ->
    gutil.log 'Publishing with credentials'.blue
    gutil.log "  - env.S3_KEY: #{env.S3_KEY.cyan}".blue
    gutil.log "  - env.S3_SECRET: #{env.S3_SECRET.cyan}".blue
    gutil.log "  - env.S3_BUCKET: #{env.S3_BUCKET.cyan}".blue
    publisher = awspublish.create { key: env.S3_KEY,  secret: env.S3_SECRET, bucket: env.S3_BUCKET }
    headers =
        'Cache-Control': 'max-age=315360000, no-transform, public'

    gulp.src "#{OUTPUT}/**/*"
        .pipe publisher.publish headers
        .pipe publisher.cache()
        .pipe awspublish.reporter()

gulp.task 'heroku:production', ['build'], ->
    gulp.start 'publish'

gulp.task 'dev', ['clean'], ->
    gulp.start 'styles', 'scripts', 'assets', 'watch'

gulp.task 'default', -> gulp.start 'dev'

gulp.task 'build', ['clean'], ->
    gulp.start 'styles', 'scripts', 'assets'