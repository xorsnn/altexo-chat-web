
angular.module('AltexoApp')

.controller 'LoginCtrl',
($scope, $location, User) ->
  if User.profile
    $location.path('/')
  else
    $scope.formData = {
      username: null
      password: null
    }
    $scope.login = ({ username, password }) ->
      User.login(username, password)
      .then -> $location.path('/')
      return
  return
