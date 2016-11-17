_ = require('lodash')

require('./json-rpc.service.coffee')
require('../_constants/al.const.coffee')

angular.module('AltexoApp')

.factory 'AltexoChat',
($q, $timeout, JsonRpc, RpcError, AL_CONST) ->

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


  class AltexoChat

    id: null
    room: null
    messages: null

    constructor: ->
      this.ws = new WebSocket("#{AL_CONST.chatEndpoint}/al_chat")
      this.rpc = new AltexoRpc()

      this.ws.addEventListener 'open', =>
        this.rpc.attach(this.ws)

      this.ws.addEventListener 'close', =>
        this.rpc.detach()

      this.$on 'contact-list', (contacts) =>
        if this.room
          prevContacts = this.room.contacts
          this.room.contacts = contacts

          modeChanged = _.differenceBy(contacts, prevContacts, 'mode')
          if modeChanged.length
            this.rpc.emit('mode-changed', modeChanged)

          added = _.differenceBy(contacts, prevContacts, 'id')
          if added.length
            this.rpc.emit('add-user', added)

          removed = _.differenceBy(prevContacts, contacts, 'id')
          if removed.length
            this.rpc.emit('remove-user', removed)

            if this.room.p2p and this.room.creator == this.id
              # peer quit, restart room for waiting offer from next peer
              this.restartRoom()

        return

      messageId = 0
      this.messages = []
      this.$on 'chat-text', (message) =>
        message.id = ++messageId
        this.messages.push(message)
        if this.messages.length > 10
          this.messages.shift()
        return

    openRoom: (name, p2p = true) ->
      this.enterRoom(name)
      .then null, (error) =>
        unless error.code == RpcError.ROOM_NOT_FOUND
          return $q.reject(error)
        this.createRoom(name, p2p)

    restartRoom: ->
      { name, p2p } = this.room
      this.room = null
      this.destroyRoom().then =>
        this.createRoom(name, p2p)

    ensureConnected: ->
      (if this.isConnected() then $q.resolve(true) \
        else $q (resolve) => this.$once 'connected', resolve)
      .then =>
        # request session user id if not cached
        if this.id == null
          this.rpc.request('id')
          .then (id) =>
            this.id = id

    isWaiter: ->
      # P2P room creator should wait for offer instead
      # of sending it's own offer to the room
      !!(this.room and this.room.p2p and this.room.creator == this.id)

    isConnected: ->
      this.ws.readyState == WebSocket.OPEN

    authenticate: (token) ->
      this.rpc.request('authenticate', [token])

    setAlias: (nickname) ->
      this.rpc.notify('user/alias', [nickname])

    setMode: (value) ->
      this.rpc.notify('user/mode', [value])

    sendMessage: (text) ->
      this.rpc.notify('room/text', [text])

    createRoom: (name, p2p) ->
      this.rpc.request('room/open', [name, p2p])
      .then (@room) => this.room

    destroyRoom: ->
      this.rpc.request('room/close')
      .then => this.room = null

    enterRoom: (name) ->
      # this.rpc.request('room/enter', [name])
      # .then (@room) => this.room

      # TODO: ugly solutions to notify creator about modes
      this.rpc.request('room/enter', [name])
      .then (@room) =>
        $timeout(0).then =>
          this.rpc.emit('mode-changed', this.room.contacts)
        this.room

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
    # use rpc object as internal event emitter
    $on: (eventName, handler) ->
      this.rpc.addListener(eventName, handler)
      return (=> this.rpc.removeListener(eventName, handler))

    $once: (eventName, handler) ->
      _offOnce = => this.rpc.removeListener(eventName, _handler)
      _handler = (param) -> handler(param) if [ _offOnce() ]
      this.rpc.addListener(eventName, _handler)
      return _offOnce
