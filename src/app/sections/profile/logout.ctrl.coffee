
angular.module('AltexoApp')

.controller 'LogoutCtrl',
($location, User) ->
  User.logout().then ->
    $location.path('/')
