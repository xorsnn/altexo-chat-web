require('./json-rpc.service.coffee')
require('../_constants/al.const.coffee')

angular.module('AltexoApp')

.factory 'AltexoChat',
($q, JsonRpc, AL_CONST) ->

  class AltexoRpc extends JsonRpc

    onAttach: ->
      this.emit 'connected', true

    sendAnswer: (answerSdp) ->
      this.emit 'answer', answerSdp

    rpc: {
      'offer': (offerSdp) ->
        this.emit 'offer', offerSdp
        return $q (resolve) =>
          this.once 'answer', resolve
    }

    rpcNotify: {
      'ice-candidate': (candidate) ->
        this.emit 'ice-candidate', candidate
    }


  class AltexoChat

    roomName: null
    p2p: null

    constructor: ->
      this.ws = new WebSocket("#{AL_CONST.chatEndpoint}/al_chat")
      this.rpc = new AltexoRpc()

      this.ws.addEventListener 'open', =>
        this.rpc.attach(this.ws)

      this.ws.addEventListener 'close', =>
        this.rpc.detach()

    authenticate: (token) ->
      this.rpc.request('authenticate', [token])

    createRoom: (name, p2p) ->
      this.rpc.request('room/open', [name, p2p])
      .then => this._setRoom(name, p2p)

    enterRoom: (name, errorCb = null) ->
      this.rpc.request('room/enter', [name])
      .then (res) =>
        this._setRoom(name, null)
        $q (resolve) -> resolve(true)
      , (err) =>
        $q (resolve, reject) -> reject(err)

    leaveRoom: ->
      this.rpc.request('room/leave')
      .then => this._setRoom(null, null)

    sendOffer: (offerSdp) ->
      this.rpc.request('room/offer', [offerSdp])

    sendCandidate: (candidate) ->
      this.rpc.notify('room/ice-candidate', [candidate])

    receiveOffer: ->
      $q (resolve) => this.$once 'offer', resolve

    sendAnswer: (answerSdp) ->
      this.rpc.sendAnswer(answerSdp)

    ensureOpen: ->
      if this.isOpen() then $q.resolve(true)
      else $q (resolve) => this.$once 'connected', resolve

    isOpen: ->
      this.ws.readyState == WebSocket.OPEN

    hasRoom: ->
      not (this.roomName is null)

    # angular-style event subscription
    $on: (eventName, handler) ->
      this.rpc.addListener(eventName, handler)
      return (=> this.rpc.removeListener(eventName, handler))

    $once: (eventName, handler) ->
      _offOnce = => this.rpc.removeListener(eventName, _handler)
      _handler = (param) -> handler(param) if [ _offOnce() ]
      this.rpc.addListener(eventName, _handler)
      return _offOnce

    _setRoom: (@roomName, @p2p) ->
