
angular.module('AltexoApp')

.controller 'StreamCtrl',
($scope, $location, $routeParams) ->

  $scope.viewLink = ->
    $location.absUrl().replace(/([^:\/])\/.+/,
      "$1/room/#{$routeParams.room}")

  $scope.onLogoClick = ->
    $location.path('/')
    return

  $scope.$on '$destroy', ->
    $scope.chat.leaveRoom()
