_ = require('lodash')

angular.module('AltexoApp')

.controller 'StreamCtrl',
($scope, $location, $routeParams, $localStorage, $mdToast, $mdSidenav, $mdDialog, \
  $timeout, $window, ScreenSharingExtension, RpcError, AlWebVR) ->

    $scope.textMessage = ''
    $scope.controls = {
      audio: true
      video: true
    }

    $scope.isVRAvaliable = AlWebVR.isVRAvaliable
    $scope.getVRBtnTooltip = AlWebVR.getVRBtnTooltip
    $scope.switchToVR = AlWebVR.switchToVR

    $timeout(500)  # wait until sidenav is closed
    .then -> $scope.chat.ensureConnected()
    .then ->
      $scope.chat.setAlias($localStorage.nickname)
    .then ->
      if $location.search().kurento
        console.log '>> OPENING KURENTO ROOM'
        $scope.chat.openRoom($routeParams.room, false)
      else
        console.log '>> OPENING P2P ROOM'
        $scope.chat.openRoom($routeParams.room, true)
    .then ->
      # add room to used
      $scope.rememberRoom($routeParams.room)

      endToastAdds = $scope.chat.room.$on 'add', (contact) ->
        $mdToast.show($mdToast.simple()
          .textContent("#{contact.name} entered this room."))

      endToastRemoves = $scope.chat.room.$on 'remove', (contact) ->
        $mdToast.show($mdToast.simple()
          .textContent("#{contact.name} leaved this room."))

      endToastUpdates = $scope.chat.room.$on 'update', (contact) ->
        $mdToast.show($mdToast.simple()
          .textContent("#{contact.name} changed mode."))

      endChatOpen = $scope.chat.$on 'chat-text', ->
        $mdSidenav('right').open()

      endRedirects = $scope.chat.$on 'room-destroyed', ->
        $mdToast.show($mdToast.simple()
          .textContent('Room was destroyed by initiator.'))
        $location.path('/')

      # TODO: handle leaving room on closing
      $scope.$on '$destroy', ->
        endToastUpdates()
        endToastAdds()
        endToastRemoves()
        endRedirects()
        endChatOpen()
        $scope.chat.leaveRoom()

      return
    .catch (error) ->
      if error.code == RpcError.ONLY_TWO_PERSONS_ALLOWED
        $mdToast.show($mdToast.simple()
          .textContent('''
            Sorry, only one guest may view this stream at a time.
            Currently the room is busy.
          '''))
      return

    $scope.viewLink = ->
      $location.absUrl().replace(/([^:\/])\/.+/,
        "$1/room/#{$routeParams.room}")

    $scope.quitRoom = ->
      $location.path('/')
      return

    $scope.setChatAlias = (value) ->
      $scope.chat.setAlias(value)

    $scope.setChatAlias = _($scope.setChatAlias).debounce(1750).value()

    $scope.sendMessage = (text) ->
      unless _.trim(text) == ''
        $scope.chat.sendMessage(text)
      $scope.textMessage = ''

    $scope.toggleShareScreen = ->
      unless ScreenSharingExtension.isAvailable()
        alertDialog = $mdDialog.alert({
          title: 'Not available'
          textContent: '''
            Sorry, screen sharing feature is not available in
            this browser. Currently it is supported in Google
            Chrome with official browser extension installed.
          '''
          ok: 'Ok'
        })
        $mdDialog.show(alertDialog)
        return
      unless ScreenSharingExtension.isInstalled()
        confirmDialog = $mdDialog.confirm({
          title: 'No extension detected'
          textContent: '''
            Please install Chrome extension to give access to
            screen sharing functions for this application.
          '''
          ok: 'Install'
          cancel: 'Cancel'
        })
        $mdDialog.show(confirmDialog)
        .then ->
          # TODO: popup is blocked, because 'ok' button handler is called with nextTick.
          # $window.open("#{AL_WEBSTORE_APP_LINK}", '_blank')
          $window.location.href = "#{AL_WEBSTORE_APP_LINK}"
        return
      $scope.chat.toggleShareScreen()
