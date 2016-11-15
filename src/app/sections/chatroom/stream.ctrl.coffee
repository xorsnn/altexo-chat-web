_ = require('lodash')

# TODO: take a look later and may be move to 'features'
require('./web-rtc-view.directive.coffee')
require('./web-rtc-view-share-screen.directive.coffee')


angular.module('AltexoApp')

.controller 'StreamCtrl',
($scope, $location, $routeParams, $localStorage, $mdToast, $mdSidenav, $log, $rootScope, RpcError, AL_VIDEO_VIS) ->

  $scope.textMessage = ''
  $scope.shareScreen = false
  $scope.controls = {
    local: { audio: true, video: true }
    remote: { audio: true, video: true }
  }

  $scope.toggleChat = ->
    $mdSidenav('right').toggle()
    return

  $scope.chat.ensureConnected()
  .then (id) ->
    $scope.chat.setAlias($localStorage.nickname)
  .then (dt) ->
    $scope.chat.openRoom($routeParams.room)
  .then (dt) ->
    # add room to used
    $scope.rememberRoom($routeParams.room)

    endChatOpen = $scope.chat.$on 'chat-text', ->
      $mdSidenav('right').open()

    modeChangeToast = $scope.chat.$on 'mode-changed', (users) ->
      mode = {
        local: null
        remote: null
      }
      users.forEach (user) ->
        unless $scope.chat.id == user.id
          mode.remote =
            {
              'id': user.id
              'name': user.name
              'mode': user.mode
            }
        else
          mode.local =
            {
              'id': user.id
              'name': user.name
              'mode': user.mode
            }

        $mdToast.show($mdToast.simple()
          .textContent("#{user.name} changed mode."))

      $rootScope.$broadcast 'al-mode-change', mode
      return

    endToastAdds = $scope.chat.$on 'add-user', (users) ->
      mode = {
        local: null
        remote: null
      }
      users.forEach (user) ->
        unless $scope.chat.id == user.id
          mode.remote =
            {
              'id': user.id
              'name': user.name
              'mode': user.mode
            }
        else
          mode.local =
            {
              'id': user.id
              'name': user.name
              'mode': user.mode
            }
        $mdToast.show($mdToast.simple()
          .textContent("#{user.name} entered this room."))

      $rootScope.$broadcast 'al-mode-change', mode
      return

    endToastRemoves = $scope.chat.$on 'remove-user', (users) ->
      users.forEach (user) ->
        $mdToast.show($mdToast.simple()
          .textContent("#{user.name} leaved this room."))

    endRedirects = $scope.chat.$on 'room-destroyed', ->
      $mdToast.show($mdToast.simple()
        .textContent('Room was destroyed by initiator.'))
      $location.path('/')

    # TODO: handle leaving room on closing
    $scope.$on '$destroy', ->
      endToastAdds()
      endToastRemoves()
      endRedirects()
      modeChangeToast()
      endChatOpen()
      $scope.chat.leaveRoom()

    return
  .catch (error) ->
    if error.code == RpcError.ONLY_TWO_PERSONS_ALLOWED
      $mdToast.show($mdToast.simple()
        .textContent('Sorry, only one guest may view this stream at a time. Currently the room is busy.'))
    return

  $scope.viewLink = ->
    $location.absUrl().replace(/([^:\/])\/.+/,
      "$1/room/#{$routeParams.room}")

  $scope.onLogoClick = ->
    $location.path('/')
    return

  $scope.setChatAlias = (value) ->
    $scope.chat.setAlias(value)

  $scope.setChatAlias = _($scope.setChatAlias).debounce(1750).value()

  $scope.sendMessage = (text) ->
    unless _.trim(text) == ''
      $scope.chat.sendMessage(text)
    $scope.textMessage = ''

  $scope.toggleVideo = ->
    $scope.controls.local.video =! $scope.controls.local.video
    $scope.chat.setMode {
      audio: $scope.controls.local.audio
      video: if $scope.controls.local.video then AL_VIDEO_VIS.RGB_VIDEO else AL_VIDEO_VIS.NO_VIDEO
    }
    return

  $scope.toggleAudio = ->
    $scope.controls.local.audio =! $scope.controls.local.audio
    $scope.chat.setMode {
      audio: $scope.controls.local.audio
      video: if $scope.controls.local.video then AL_VIDEO_VIS.RGB_VIDEO else AL_VIDEO_VIS.NO_VIDEO
    }
    return

  $scope.toggleShareScreen = ->
    # TODO: probably we should send a message to peer for restarting session
    $scope.shareScreen = not $scope.shareScreen
