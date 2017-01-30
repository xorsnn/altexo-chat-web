EventEmitter = require('eventemitter').EventEmitter
_ = require('lodash')


angular.module('AltexoApp')

.factory 'ChatRoom', ->

  class ChatRoom extends EventEmitter

    name: null
    p2p: null
    contacts: null

    _chat: null

    constructor: (chat) ->
      this._chat = chat
      this.contacts = new Map()
      super()

    selectVideoElement: (contact) ->
      if this.p2p
        if contact.id == this.creator
          return this._chat.localVideo
        return this._chat.remoteVideo
      return this._chat.remoteVideo

    updateInfo: ({ name, creator, p2p }) ->
      this.name = name
      this.p2p = p2p
      this.creator = creator
      return this

    updateContacts: (contactList) ->
      contacts = new Map(contactList.map (contact) -> [contact.id, contact])

      removed = []
      added = []
      updated = []

      # remove gone contacts
      this.contacts.forEach (contact) =>
        unless contacts.get(contact.id)
          this.contacts.delete(contact.id)
          removed.push(contact)
        return

      # add came contacts and update changed
      contacts.forEach (contact) =>
        prev = this.contacts.get(contact.id)
        unless prev
          this.contacts.set(contact.id, contact)
          added.push(contact)
        else if not _.isEqual(prev, contact)
          this.contacts.set(contact.id, contact)
          updated.push(contact)
        return

      for contact in removed
        this.emit('remove', contact)

      for contact in added
        this.emit('add', contact)

      for contact in updated
        this.emit('update', contact)

      if this.p2p and removed.length
        this._chat.restartRoom()

      return this

    # angular-style event subscription
    $on: (eventName, handler) ->
      this.addListener(eventName, handler)
      return (=> this.removeListener(eventName, handler))
