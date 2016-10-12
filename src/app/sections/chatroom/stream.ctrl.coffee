
angular.module('AltexoApp')

.controller 'StreamCtrl',
($scope, $q, $location, $routeParams, $mdToast, AlRoomsService, RpcError) ->

  $scope.chat.ensureConnected()
  .then -> $scope.chat.openRoom($routeParams.room)
  .then ->
    # add room to used
    AlRoomsService.roomUsed($routeParams.room)

    endChatUpdates = $scope.chat.$on 'update', ->
      $scope.$digest()

    # TODO: handle leaving room on closing
    $scope.$on '$destroy', ->
      endChatUpdates()
      $scope.chat.leaveRoom()

    return
  .catch (error) ->
    if error.code == RpcError.ONLY_TWO_PERSONS_ALLOWED
      $mdToast.show($mdToast.simple()
        .textContent('Sorry, only one guest may view this stream at a time. Currently the room is busy.'))
    return

  $scope.viewLink = ->
    $location.absUrl().replace(/([^:\/])\/.+/,
      "$1/room/#{$routeParams.room}")

  $scope.onLogoClick = ->
    $location.path('/')
    return
