MAXROOMS = 6

angular.module('AltexoApp')

.controller 'RootCtrl',
($scope, $localStorage, AltexoChat) ->

  $scope.$storage = $localStorage.$default {
    nickname: 'Anonymous'
    usedRooms: []
  }

  $scope.chat = new AltexoChat()

  $scope.rememberRoom = (name) ->
    { usedRooms } = $scope.$storage
    unless (j = usedRooms.indexOf(name)) == -1
      usedRooms.splice(j, 1)
    usedRooms.unshift(name)
    unless usedRooms.length <= MAXROOMS
      usedRooms.pop()
    return

  return
