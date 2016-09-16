
angular.module('AltexoApp')

.controller 'StartStreamCtrl',
($scope, $location, AuthTokenService, AlRoomsService, Storage) ->
  # TODO: make default kurento use false untill payment configured
  # defaultKurentoUse = Storage.get('defaultKurentoUse')
  # defaultKurentoUse = defaultKurentoUse == true ? true : false
  defaultKurentoUse = false

  $scope.room = {
    name: AlRoomsService.getLatestRoom()
    kurento: defaultKurentoUse
  }

  $scope.kurentoClick = (kurentoVal) ->
    Storage.set('defaultKurentoUse', kurentoVal)
    return

  $scope.createRoom = (chat, room) ->
    # add room to used
    AlRoomsService.roomUsed(room.name)

    chat.ensureOpen()
    .then -> chat.authenticate(AuthTokenService.auth_token)
    .then -> chat.createRoom(room.name, (not room.kurento))
    .then -> $location.path('/stream')

  $scope.$on 'alUsedRoomClicked', (event, roomClicked) ->
    $scope.room.name = roomClicked
