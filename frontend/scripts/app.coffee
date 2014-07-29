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
            controller: 'IndexCtrl as indx'
        .state 'gif',
            url: '/list'
            templateUrl: 'list.html'

gifsApp.controller 'IndexCtrl', (Gif, $rootScope, $scope) ->
    @previewUrl = 'http://d114b3t5xlnw3o.cloudfront.net/uploads/obama-crying.gif'
    @gifs = Gif.query()

    @hover = (gif) ->
        $rootScope.$broadcast 'gifs.updatePreview', gif
        @previewUrl = gif.url

    $rootScope.$on 'gifs.refreshIndex', =>
        console.log 'refreshing gifs'
        @gifs.$query()

    return @

gifsApp.controller 'UploadCtrl', (Gif, gifUploader, $http, $rootScope, $scope, $upload) ->

    @onFileSelect = ($files) =>
        @files = $files

        _saveGif = (gifData) ->
            gif = new Gif {
                title: gifData.fileName
                path: gifData.path
            }

            gif.$create()

        for file in $files
            @uploading = true
            file.progress = 0
            gifUploader file
                .then _saveGif
                .then (data) =>
                    @uploading = false
                    $rootScope.$broadcast 'gifs.refreshIndex'

    return @

gifsApp.service 'gifUploader', ($http, $q, $upload) ->
    (file) ->
        _makeObjectKey = (file) ->
            [parts..., ext] = file.name.split '.'
            name = parts.join('').replace(/[^\w ]+/g, '').replace RegExp(' +', 'g'), '-'
            random = Math.random().toString(36).substr 2, 6
            file._path = "uploads/#{name}-#{random}.#{ext}"
            file._path

        _uploadToS3 = (signingResponse) ->
            s3Params = signingResponse.data
            $upload.upload
                url: s3Params.endpoint
                method: 'POST'
                file: file
                data:
                    key: _makeObjectKey file
                    acl: s3Params.acl
                    'Content-Type' : file.type,
                    'AWSAccessKeyId': s3Params.AWSAccessKeyId,
                    'success_action_status' : '201',
                    'Policy' : s3Params.policy,
                    'Signature' : s3Params.signature

        _done = (s3Resp) ->
            file.progress = 100
            data = xml2json.parser s3Resp.data

            return dfd.reject data  unless s3Resp.status is 201

            parsedData =
                path:     file._path
                fileName: file.name
                location: decodeURIComponent data.postresponse.location
                key:      data.postresponse.key

            dfd.resolve parsedData

        _onError = (err) -> dfd.reject err
        _reportProgress = (evt) -> console.log '  progress', evt

        dfd = $q.defer()

        $http.get "/api/sign?mimeType=#{file.type}"
            .then _uploadToS3
            .then _done, null, _reportProgress
            .catch _onError

        dfd.promise

gifsApp.factory 'transform', ->
    response: (key) ->
        (raw) ->
            if _.isNull(key) then null else angular.fromJson(raw)[key]

gifsApp.factory 'Gif', ($resource, transform) ->
    $resource '/api/gifs/:id', {id: '@_id'},
        query:
            method: 'GET'
            transformResponse: transform.response 'gifs'

        update:
            method: 'PUT'

        create:
            method: 'POST'