
class AlStartStreamCtrl
  ### @ngInject ###
  constructor: ($scope, $location, $localStorage, AuthTokenService, Storage) ->
    @scope = $scope
    @location = $location

    # TODO: make default kurento use false untill payment configured
    # defaultKurentoUse = Storage.get('defaultKurentoUse')
    # defaultKurentoUse = defaultKurentoUse == true ? true : false
    defaultKurentoUse = false

    $scope.room = {
      name: "#{Math.floor(Math.random() * 1e9)}"
      kurento: defaultKurentoUse
    }

    if $localStorage.usedRooms.length
      $scope.room.name = $localStorage.usedRooms[0]

    $scope.kurentoClick = (kurentoVal) ->
      Storage.set('defaultKurentoUse', kurentoVal)
      return

    $scope.createRoom = (chat, room) ->
      $location.path("/room/#{room.name}")
      return

    $scope.$on 'alUsedRoomClicked', (event, roomClicked) ->
      $scope.room.name = roomClicked
    return

angular.module('AltexoApp')
.controller 'StartStreamCtrl', AlStartStreamCtrl
