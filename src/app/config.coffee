
angular.module('AltexoApp')

.config ($httpProvider, $routeProvider, $locationProvider, $mdThemingProvider) ->
  auth = ['User', (User) -> User.authenticate()]

  $routeProvider
  .when '/', {
    templateUrl: 'sections/chatroom/start.pug'
    controller: 'StartStreamCtrl'
  }
  .when '/room/:room', {
    templateUrl: 'sections/chatroom/stream.pug'
    controller: 'StreamCtrl'
  }
  .when '/login', {
    templateUrl: 'sections/profile/login.pug'
    controller: 'LoginCtrl'
  }
  .when '/logout', {
    resolve: { auth }
    templateUrl: 'sections/profile/logout.pug'
    controller: 'LogoutCtrl'
  }
  .when '/register', {
    templateUrl: 'sections/profile/register.pug'
    controller: 'RegisterCtrl'
  }
  .when '/register/activate/:uid/:token', {
    templateUrl: 'sections/profile/activate.pug'
    controller: 'ActivateCtrl'
  }
  .when '/not-supported', {
    templateUrl: 'features/modernizr/_not_supported.pug'
    controller: 'AlNotSupportedCtrl'
    controllerAs: 'AlNotSupportedCtrl'
  }

  # Enable html5Mode for pushstate ('#'-less URLs)
  unless DEBUG == 'true'
    $locationProvider.html5Mode(true)
    $locationProvider.hashPrefix('!')

  $mdThemingProvider.theme('default')
  .primaryPalette('blue-grey')
  .accentPalette('cyan')

  $httpProvider.defaults.xsrfCookieName = 'csrftoken'
  $httpProvider.defaults.xsrfHeaderName = 'X-CSRFToken'

  return
