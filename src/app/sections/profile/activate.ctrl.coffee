
angular.module('AltexoApp')

.controller 'ActivateCtrl',
($scope, $routeParams, AccountsApi) ->
  $scope.confirmed = null
  AccountsApi.activateUser($routeParams.uid, $routeParams.token)
  .then ->
    $scope.confirmed = 'yes'
  .catch ->
    $scope.confirmed = 'no'
  return
