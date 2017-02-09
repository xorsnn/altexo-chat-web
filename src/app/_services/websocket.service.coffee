
angular.module('AltexoApp')

.service '$websocket', (AL_CONST) ->
  new WebSocket("#{AL_CONST.chatEndpoint}/al_chat")
