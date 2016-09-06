
angular.module('AltexoApp')

.controller 'StreamCtrl',
($scope, $location) ->

  $scope.viewLink = ->
    $location.absUrl().replace(/([^:\/])\/.+/,
      "$1/chat/room/#{$scope.chat.roomName}")

  $scope.$on '$destroy', ->
    $scope.chat.leaveRoom()
