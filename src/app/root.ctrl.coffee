MAXROOMS = 6

angular.module('AltexoApp')

.controller 'RootCtrl',
($scope, $localStorage, $mdSidenav, $route, $mdMedia, AltexoChat) ->

  $scope.$storage = $localStorage.$default {
    token: null
    nickname: 'Anonymous'
    usedRooms: []
  }

  $scope.chat = new AltexoChat()

  Object.defineProperty $scope, 'leftSidenav', {
    get: -> $mdSidenav('left')
  }

  $scope.rememberRoom = (name) ->
    { usedRooms } = $scope.$storage
    unless (j = usedRooms.indexOf(name)) == -1
      usedRooms.splice(j, 1)
    usedRooms.unshift(name)
    unless usedRooms.length <= MAXROOMS
      usedRooms.pop()
    return

  $scope.desktopMode = ->
    if $route.current
      if $route.current.controller == 'StreamCtrl'
        return false
    return $mdMedia('gt-sm')

  return
