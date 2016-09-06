
class AlRoomsService
  ### @ngInject ###
  constructor: (Storage) ->
    @storage = Storage
    @usedRooms = @storage.get('usedRooms')
    unless @usedRooms
      @usedRooms = []
    return

  roomUsed: (roomName) ->
    unless roomName in @usedRooms
      @usedRooms.unshift(roomName)
      while @usedRooms.length > 6
        @usedRooms.pop()
      @storage.set('usedRooms', @usedRooms)
    return

  getLatestRoom: () ->
    for room in @usedRooms
      return room
    return String(Math.floor(Math.random()*1e9))

angular.module('AltexoApp')
.service 'AlRoomsService', AlRoomsService
