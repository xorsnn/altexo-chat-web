
angular.module('AltexoApp')

.controller 'RegisterCtrl',
($scope, $location, $django, AccountsApi) ->
  $scope.formSent = false
  $scope.formError = null
  $scope.formData = {}
  $scope.submit = (ev, { username, email, password, password2 }) ->
    ev.preventDefault()
    unless password == password2
      $scope.formError = $django.errorToAngularMessages({
        password2: ['Passwords do not match.']
      })
    else
      AccountsApi.registerUser(email, username, password)
      .then ->
        $scope.formSent = true
      .catch (reason) ->
        $scope.formError = $django.errorToAngularMessages(reason)
    return
  return
