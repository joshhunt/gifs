gifsApp = angular.module 'gifs', [
    'gifs-templates'

    'ui.router'
    'ngResource'
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
