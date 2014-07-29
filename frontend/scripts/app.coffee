gifsApp = angular.module 'gifs', [
    'gifs-templates'

    'ui.router'
    'ngResource'
    'angularFileUpload'
]

gifsApp.config ($stateProvider, $locationProvider, $urlRouterProvider) ->

    $locationProvider.html5Mode(true)

    # redirect trailing slashes to non-trailing slashes
    $urlRouterProvider.rule ($injector, $location) ->
        path = $location.url()

        # check to see if the path has a trailing slash
        return path.replace(/\/$/, '')  if '/' is path[path.length - 1]
        return path.replace('/?', '?')  if path.indexOf('/?') > -1
        false

    $stateProvider
        .state 'index',
            url: '/'
            templateUrl: 'index.html'
            controller: 'IndexCtrl'
        .state 'gif',
            url: '/list'
            templateUrl: 'list.html'

gifsApp.controller 'IndexCtrl', ($scope, Gif) ->
    $scope.previewUrl = 'http://d114b3t5xlnw3o.cloudfront.net/uploads/obama-crying.gif'
    $scope.gifs = Gif.query()

gifsApp.controller 'UploadCtrl', ($http, $scope, $upload) ->

    $scope.imageUploads

    _formatName = (filename) ->
        [parts..., ext] = filename.split '.'
        name = parts.join ''
        name = name.toLowerCase().replace(/[^\w ]+/g, '').replace RegExp(' +', 'g'), '-'
        "#{name}.#{ext}"

    @onFileSelect = ($files) =>
        @files = $files
        @uploads = []
        @imageUploads = []
        window.imageUploads = @imageUploads

        for file in $files
            file.progress = 0
            file.key = file.lastModifiedDate + file.name + file.type + file.size

            _processFile = (file) =>
                $http.get("/api/sign?mimeType=#{file.type}").success (resp) =>
                    s3Params = resp
                    console.log 'Got signing data:', resp
                    console.log 'uploading...'
                    @uploads[file.key] = $upload.upload(
                        url: 'https://gifsjoshhunt.s3.amazonaws.com/' # todo: don't hard code this
                        method: 'POST'
                        file: file
                        data:
                            'key': 'uploads/' + _formatName file.name
                            'acl': 'public-read'
                            'Content-Type' : file.type,
                            'AWSAccessKeyId': s3Params.AWSAccessKeyId,
                            'success_action_status' : '201',
                            'Policy' : s3Params.s3Policy,
                            'Signature' : s3Params.s3Signature
                    ).then((resp) =>
                        console.log 'File upload promise resolved with', resp
                        file.progress = 100
                        if resp.status is 201
                            data = xml2json.parser resp.data
                            parsedData =
                                location: decodeURICompontent data.postresponse.location
                                bucket:   data.postresponse.bucket
                                etag:     data.postresponse.etag
                                key:      data.postresponse.key

                            console.log 'upload complete', parsedData
                            @imageUploads.push parsedData
                    , null, (evt) ->
                        console.log 'progress event:', evt
                        file.progress = parseInt 100.0 * evt.loaded / evt.total
                    )

            _processFile file

    return @

gifsApp.factory 'transform', ->
    response: (key) ->
        (raw) ->
            if _.isNull(key) then null else angular.fromJson(raw)[key]

gifsApp.factory 'Gif', ($resource, transform) ->
    $resource '/api/gifs/:id', {id: '@id'},
        query:
            method: 'GET'
            transformResponse: transform.response 'gifs'

        update:
            method: 'PUT'
