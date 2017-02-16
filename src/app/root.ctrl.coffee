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

  Object.defineProperties $scope, {
    rightSidenav: { get: -> $mdSidenav('right') }
    leftSidenav: { get: -> $mdSidenav('left') }
    leftSidenavLocked: {
      get: ->
        unless $route.current?.controller == 'StreamCtrl'
          return $mdMedia('gt-sm')
        return false
    }
  }

  $scope.rememberRoom = (name) ->
    { usedRooms } = $scope.$storage
    unless (j = usedRooms.indexOf(name)) == -1
      usedRooms.splice(j, 1)
    usedRooms.unshift(name)
    unless usedRooms.length <= MAXROOMS
      usedRooms.pop()
    return

  return
