
require('./sections/chatroom/start-stream.ctrl.coffee')
require('./sections/chatroom/start.pug')

require('./sections/chatroom/stream.ctrl.coffee')
require('./sections/chatroom/stream.pug')

angular.module('AltexoApp')
.config ($httpProvider, $routeProvider, $locationProvider, $mdThemingProvider) ->
  $httpProvider.interceptors.push 'httpRequestInterceptor'

  $routeProvider
  .when '/', {
    templateUrl: 'sections/chatroom/start.pug'
    controller: 'StartStreamCtrl'
  }
  .when '/room/:room', {
    templateUrl: 'sections/chatroom/stream.pug'
    controller: 'StreamCtrl'
  }

  #  enable html5Mode for pushstate ('#'-less URLs)
  $locationProvider.html5Mode(true)
  $locationProvider.hashPrefix('!')

  $mdThemingProvider.theme('default')
  .primaryPalette('blue-grey')
  .accentPalette('cyan')

  $httpProvider.defaults.xsrfCookieName = 'csrftoken'
  $httpProvider.defaults.xsrfHeaderName = 'X-CSRFToken'
  return
