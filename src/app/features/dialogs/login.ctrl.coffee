
angular.module('AltexoApp')

.controller 'LoginDialogCtrl',
($scope, $mdDialog, $django, User) ->
  closeDialog = ->
    $mdDialog.hide(User)
  $scope.formError = null
  $scope.formData = {}
  $scope.login = ({ username, password }) ->
    User.login(username, password)
    .then(closeDialog)
    .catch (reason) ->
      $scope.formError = $django.errorToAngularMessages(reason)
  $scope.cancel = ->
    $mdDialog.cancel()
  return
