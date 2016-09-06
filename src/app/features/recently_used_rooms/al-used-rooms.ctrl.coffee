
class AlUsedRoomsController
  ### @ngInject ###
  constructor: ($rootScope, AlRoomsService) ->
    @rootScope = $rootScope
    @AlRoomsService = AlRoomsService
    return

  onUsedRoomClicked: (roomClicked) ->
    @rootScope.$broadcast 'alUsedRoomClicked', roomClicked
    return

module.exports = AlUsedRoomsController
