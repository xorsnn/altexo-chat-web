require('./al-used-rooms.pug')

angular.module('AltexoApp')
.component 'alUsedRooms', {
  templateUrl: 'features/recently_used_rooms/al-used-rooms.pug'
  controller: ($scope, $localStorage) ->
    $scope.usedRooms = $localStorage.usedRooms
}
