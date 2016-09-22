
angular.module('AltexoApp')

.controller 'StreamCtrl',
($scope, $location) ->

  $scope.viewLink = ->
    $location.absUrl().replace(/([^:\/])\/.+/,
      "$1/room/#{$scope.chat.roomName}")

  $scope.onLogoClick = ->
    $location.path('/')
    return

  $scope.$on '$destroy', ->
    $scope.chat.leaveRoom()
