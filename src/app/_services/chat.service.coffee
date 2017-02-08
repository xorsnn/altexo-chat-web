angular.module('AltexoApp')

.factory 'AltexoChat',
($q, $timeout, JsonRpc, RpcError, ChatRoom, AL_CONST, AL_VIDEO) ->

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


  class AltexoChat

    rpc: null
    id: null
    room: null
    messages: null
    _webRtcRestarting: false

    constructor: ->
      this.ws = new WebSocket("#{AL_CONST.chatEndpoint}/al_chat")
      this.rpc = new AltexoRpc()

      this.ws.addEventListener 'open', =>
        this.rpc.attach(this.ws)

      this.ws.addEventListener 'close', =>
        this.rpc.detach()

      ##
      # Create video elements to handle video data.
      # These elements are not considered to be part of DOM tree,
      # BUT
      # we should keep them hidden in real DOM because
      # without that no sound will be played.
      #
      Object.defineProperty(this, 'localVideo', {
        get: -> document.getElementById('localVideo')
      })

      Object.defineProperty(this, 'remoteVideo', {
        get: -> document.getElementById('remoteVideo')
      })

      ##
      # Handle contact list updates.
      # Emit events for user adds, user leaves and user mode changes.
      #
      this.$on 'contact-list', (contacts) =>
        if this.room
          this.room.updateContacts(contacts)

      ##
      # Handle requests for WebRTC restart.
      # Restart is confirmed when WebRTC component is ready for new connection.
      #
      this.$on 'request-restart', =>
        $timeout(0)
        .then => this._webRtcRestarting = true
        .then => $timeout(0)
        .then => this._webRtcRestarting = false
        .then => this._waitWebRtcReady()
        .then => this.rpc.confirmRestart()

      ##
      # Handle chat messages.
      # Assign each message unique id and add it to message history.
      # Only 10 last messages are kept.
      #
      messageId = 0
      this.messages = []
      this.$on 'chat-text', (message) =>
        message.id = ++messageId
        this.messages.push(message)
        if this.messages.length > 10
          this.messages.shift()
        return

      return

    openRoom: (name, p2p=true) ->
      this.enterRoom(name)
      .then null, (error) =>
        unless error.code == RpcError.ROOM_NOT_FOUND
          return $q.reject(error)
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

    isRestarting: ->
      this._webRtcRestarting

    authenticate: (token) ->
      this.rpc.request('authenticate', [token])

    setAlias: (nickname) ->
      this.rpc.notify('user/alias', [nickname])

    toggleAudio: (value) ->
      this.rpc.switchMode \
        unless value then { audio: false }
        else { audio: true }

    toggleVideo: (value) ->
      this.rpc.switchMode \
        unless value then { video: AL_VIDEO.NO_VIDEO }
        else { video: AL_VIDEO.RGB_VIDEO }

    toggleShareScreen: (value) ->
      unless value?
        value = not (this.rpc.mode.video == AL_VIDEO.SHARED_SCREEN_VIDEO)

      # when we are creator in p2p room:
      # 1. Restart self and change video stream to shared screen
      # 2. Wait for a call
      # 3. Request peer to restart

      # when we are companion in p2p room:
      # 1. Request peer to restart
      # 2. Restart self
      # 3. Call

      # when we are not in p2p room:
      # 1. Restart peer
      # 2. Restart self
      # 3. Call

      if this.room.p2p and this.room.creator == this.id
        $timeout(0).then => this._webRtcRestarting = true
        .then =>
          this.rpc.switchMode \
            unless value then { video: AL_VIDEO.RGB_VIDEO }
            else { video: AL_VIDEO.SHARED_SCREEN_VIDEO }
        .then => this._webRtcRestarting = false
        .then => this._waitWebRtcReady()
        .then => this._restartPeer()
      else
        $timeout(0).then => this._restartPeer()
        .then => this._webRtcRestarting = true
        .then =>
          this.rpc.switchMode \
            unless value then { video: AL_VIDEO.RGB_VIDEO }
            else { video: AL_VIDEO.SHARED_SCREEN_VIDEO }
        .then => this._webRtcRestarting = false

    sendMessage: (text) ->
      this.rpc.notify('room/text', [text])

    createRoom: (name, p2p) ->
      this.rpc.request('room/open', [name, p2p])
      .then (data) => this._createRoom(data)

    destroyRoom: ->
      this.rpc.request('room/close')
      .then => this.room = null

    restartRoom: ->
      # Keep original room object alive, but remove
      # the reference until the room is restarted.
      room = this.room
      this.room = null
      this.destroyRoom()
      .then =>
        this.rpc.request('room/open', [room.name, room.p2p])
      .then ({ contacts }) =>
        this.room = room.updateContacts(contacts)

    enterRoom: (name) ->
      this.rpc.request('room/enter', [name])
      .then (data) => this._createRoom(data)

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

    signalWebRtcReady: ->
      this.rpc.emit 'web-rtc-ready', true

    _createRoom: (roomData) ->
      this.room = new ChatRoom(this).updateInfo(roomData)
      this.room.updateContacts(roomData.contacts)

    _waitWebRtcReady: ->
      $q (resolve) => this.$once 'web-rtc-ready', resolve

    _restartPeer: ->
      this.rpc.request('peer/restart')

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
