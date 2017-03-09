
angular.module('AltexoApp')

.service '$websocket', (AL_CONST) ->
  $websocket = new WebSocket("#{AL_CONST.chatEndpoint}/al_chat")

  $websocket.addEventListener 'open', ->
    console.debug '>> $websocket:', "OPEN #{AL_CONST.chatEndpoint}/al_chat}"

  $websocket.addEventListener 'close', ->
    console.debug '>> $websocket:', 'CLOSE'

  $websocket.addEventListener 'error', (error) ->
    console.error '>> $websocket:', error

  return $websocket
