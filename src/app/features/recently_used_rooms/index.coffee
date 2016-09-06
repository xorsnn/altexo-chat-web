# AlUsedRoomsComponent = require('./al-used-rooms.component.coffee')
AlUsedRoomsController = require('./al-used-rooms.ctrl.coffee')
require('./al-used-rooms.pug')

angular.module('AltexoApp')
.component 'alUsedRooms', {
  templateUrl: 'features/recently_used_rooms/al-used-rooms.pug'
  # templateUrl: require('./al-used-rooms.pug')
  controller: ($rootScope, AlRoomsService) -> new AlUsedRoomsController($rootScope, AlRoomsService)
}
