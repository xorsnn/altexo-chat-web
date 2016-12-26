_ = require('lodash')

# TODO: take a look later and may be move to 'features'
require('./web-rtc-view.directive.coffee')


angular.module('AltexoApp')

.controller 'StreamCtrl',
($scope, $location, $routeParams, $localStorage, $mdToast, $mdSidenav, $mdDialog, $window, ScreenSharingExtension, RpcError) ->

  $scope.textMessage = ''
  $scope.controls = {
    audio: true
    video: true
  }

  $scope.toggleChat = ->
    $mdSidenav('right').toggle()
    return

  $scope.chat.ensureConnected()
  .then ->
    $scope.chat.setAlias($localStorage.nickname)
  .then ->
    # $scope.chat.openRoom($routeParams.room, false)
    $scope.chat.openRoom($routeParams.room, true)
  .then ->
    # add room to used
    $scope.rememberRoom($routeParams.room)

    endChatOpen = $scope.chat.$on 'chat-text', ->
      $mdSidenav('right').open()

    endToastModeChanges = $scope.chat.$on 'mode-changed', (user) ->
      $mdToast.show($mdToast.simple()
        .textContent("#{user.name} changed mode."))
      return

    endToastAdds = $scope.chat.$on 'add-user', (users) ->
      users.forEach (user) ->
        $mdToast.show($mdToast.simple()
          .textContent("#{user.name} entered this room."))
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
      endToastModeChanges()
      endToastAdds()
      endToastRemoves()
      endRedirects()
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

  $scope.toggleShareScreen = ->
    unless ScreenSharingExtension.isAvailable()
      alertDialog = $mdDialog.alert({
        title: 'Not available'
        textContent: 'Sorry, screen sharing feature is not available in this browser. Currently it is supported in Google Chrome with official browser extension installed.'
        ok: 'Ok'
      })
      $mdDialog.show(alertDialog)
      return
    # unless (chrome and chrome.app and chrome.app.isInstalled)
    #   alertDialog = $mdDialog.alert({
    #     title: 'No extension detected'
    #     htmlContent: '<button>Add to Chrome</button>'
    #     ok: 'Ok'
    #   })
    #   $mdDialog.show(alertDialog)
    #   return
    unless ScreenSharingExtension.isInstalled()
      confirmDialog = $mdDialog.confirm({
        title: 'No extension detected'
        textContent: 'Please install Chrome extension to give access to screen sharing functions for this application.'
        ok: 'Install'
        cancel: 'Cancel'
      })
      $mdDialog.show(confirmDialog)
      .then ->
        # TODO: popup is blocked, because 'ok' button handler is called with nextTick.
        # $window.open('https://chrome.google.com/webstore/category/extensions', '_blank')
        $window.location.href = 'https://chrome.google.com/webstore/category/extensions'
      return
    $scope.chat.toggleShareScreen()
