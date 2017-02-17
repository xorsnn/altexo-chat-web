
angular.module('AltexoApp')

.controller 'LoginCtrl',
($scope, $location, $django, User) ->
  redirect = ->
    $location.path("/#{$location.search().redirect ? ''}")
  if User.profile.id
    redirect()
  else
    $scope.formError = null
    $scope.formData = {}
    $scope.login = ({ username, password }) ->
      User.login(username, password)
      .then(redirect)
      .catch (reason) ->
        $scope.formError = $django.errorToAngularMessages(reason)
        console.log '>> ERROR', $scope.formError
  return
