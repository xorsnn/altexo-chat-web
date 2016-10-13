
angular.module('AltexoApp')

.controller 'StreamCtrl',
($scope, $location, $timeout, $routeParams, $mdToast, AlRoomsService, RpcError) ->

  $scope.chat.ensureConnected()
  .then -> $scope.chat.openRoom($routeParams.room)
  .then ->
    # add room to used
    AlRoomsService.roomUsed($routeParams.room)

    endScopeUpdates = $scope.chat.$on 'update', ->
      $scope.$digest()

    endToastAdds = $scope.chat.$on 'add-user', (users) ->
      users.forEach (user) ->
        $mdToast.show($mdToast.simple()
          .textContent("#{user.name} entered this room."))

    endToastRemoves = $scope.chat.$on 'remove-user', (users) ->
      users.forEach (user) ->
        $mdToast.show($mdToast.simple()
          .textContent("#{user.name} leaved this room."))

    endRedirects = $scope.chat.$on 'room-destroyed', ->
      $mdToast.show($mdToast.simple()
        .textContent('Room was destroyed by initiator.'))
      $timeout(500).then ->
        $location.path('/')

    # TODO: handle leaving room on closing
    $scope.$on '$destroy', ->
      endScopeUpdates()
      endToastAdds()
      endToastRemoves()
      endRedirects()
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
