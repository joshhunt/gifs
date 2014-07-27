gifsApp = angular.module 'gifs', [
    'gifs-templates'

    'ui.router'
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
        .state 'gif',
            url: '/list'
            templateUrl: 'list.html'