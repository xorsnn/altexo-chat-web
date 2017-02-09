
angular.module('AltexoApp')

.factory 'AltexoRpc',
($q, $timeout, JsonRpc, AL_VIDEO) ->

  class AltexoRpc extends JsonRpc

    # NOTE: read-only access is suggested
    # mode: null
    mode: {}

    onAttach: ->
      this.mode = {
        audio: true
        video: AL_VIDEO.RGB_VIDEO
      }
      this.emit 'connected', true

    sendAnswer: (answerSdp) ->
      this.emit 'answer', answerSdp

    switchMode: (mode) ->
      $timeout(0).then =>
        for own prop, value of mode
          this.mode[prop] = value
        this.notify('user/mode', [this.mode])

    confirmRestart: ->
      this.emit 'confirm-restart', true

    rpc: {
      'restart': ->
        this.emit 'request-restart'
        return $q (resolve) =>
          this.once 'confirm-restart', resolve

      'offer': (offerSdp) ->
        this.emit 'offer', offerSdp
        return $q (resolve) =>
          this.once 'answer', resolve
    }

    rpcNotify: {
      'ice-candidate': (candidate) ->
        this.emit 'ice-candidate', candidate

      'room/contacts': (data) ->
        $timeout(0).then =>
          this.emit 'contact-list', data

      'room/text': (text, contact) ->
        $timeout(0).then =>
          this.emit 'chat-text', { text, contact }

      'room/destroy': ->
        $timeout(0).then =>
          this.emit 'room-destroyed'
    }
