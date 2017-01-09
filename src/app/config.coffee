
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
  .when '/not-supported', {
    templateUrl: 'features/modernizr/_not_supported.pug'
    controller: 'AlNotSupportedCtrl'
    controllerAs: 'AlNotSupportedCtrl'
  }

  #  enable html5Mode for pushstate ('#'-less URLs)
  unless DEBUG == 'true'
    $locationProvider.html5Mode(true)
    $locationProvider.hashPrefix('!')

  $mdThemingProvider.theme('default')
  .primaryPalette('blue-grey')
  .accentPalette('cyan')

  $httpProvider.defaults.xsrfCookieName = 'csrftoken'
  $httpProvider.defaults.xsrfHeaderName = 'X-CSRFToken'
  return

.run ($rootScope, $location, AlModernizrService) ->
  $rootScope.$on '$routeChangeStart', (event, next, current) ->
    unless next.$$route.originalPath == '/not-supported'
      unless AlModernizrService.check()
        event.preventDefault()
        $location.path('/not-supported')
    return
