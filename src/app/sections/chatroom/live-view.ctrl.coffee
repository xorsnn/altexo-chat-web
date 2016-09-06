
angular.module('AltexoApp')

.controller 'LiveViewCtrl',
($scope, $routeParams) ->
  $scope.enterRoom = (chat) ->
    chat.ensureOpen()
    .then -> chat.enterRoom($routeParams.room)

  $scope.$on '$destroy', ->
    $scope.chat.leaveRoom()
