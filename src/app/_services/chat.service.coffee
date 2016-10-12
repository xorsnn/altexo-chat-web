require('./json-rpc.service.coffee')
require('../_constants/al.const.coffee')

angular.module('AltexoApp')

.factory 'AltexoChat',
($q, JsonRpc, RpcError, AL_CONST) ->

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

      'contact-list': (data) ->
        this.emit 'contact-list', data
    }


  class AltexoChat

    room: null

    constructor: ->
      this.ws = new WebSocket("#{AL_CONST.chatEndpoint}/al_chat")
      this.rpc = new AltexoRpc()

      this.ws.addEventListener 'open', =>
        this.rpc.attach(this.ws)

      this.ws.addEventListener 'close', =>
        this.rpc.detach()

    openRoom: (name, p2p=true) ->
      this.enterRoom(name)
      .then null, (error) =>
        unless error.code == RpcError.ROOM_NOT_FOUND
          return $q.reject(error)
        this.createRoom(name, p2p)

    isWaiter: ->
      !not (this.room and this.room.p2p and this.room.creator == this.id)

    ensureConnected: ->
      (if this.isConnected() then $q.resolve(true) \
        else $q (resolve) => this.$once 'connected', resolve)
      .then =>
        this.$on 'contact-list', (data) =>
          this.room.contacts = data
          this.rpc.emit('update')
        this.rpc.request('id')
      .then (id) =>
        this.id = id

    isConnected: ->
      this.ws.readyState == WebSocket.OPEN

    authenticate: (token) ->
      this.rpc.request('authenticate', [token])

    createRoom: (name, p2p) ->
      this.rpc.request('room/open', [name, p2p])
      .then (roomData) => this.room = roomData

    enterRoom: (name) ->
      this.rpc.request('room/enter', [name])
      .then (roomData) => this.room = roomData

    leaveRoom: ->
      this.rpc.request('room/leave')
      .then => this.room = null

    sendOffer: (offerSdp) ->
      this.rpc.request('room/offer', [offerSdp])

    sendCandidate: (candidate) ->
      this.rpc.notify('room/ice-candidate', [candidate])

    receiveOffer: ->
      $q (resolve) => this.$once 'offer', resolve

    sendAnswer: (answerSdp) ->
      this.rpc.sendAnswer(answerSdp)

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
