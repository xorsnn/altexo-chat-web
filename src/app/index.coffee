'use strict'

require('ngstorage')
require('angular-sanitize')

Raven.config(AL_SENTRY_ENDPOINT, {
  ignoreUrls: [ /<raven_urls_to_ignore>/ ]
} ).addPlugin(require('raven-js/plugins/angular'), angular).install()


APP = angular.module 'AltexoApp', [
  'ngMaterial'
  'ngRoute'
  'ngRaven'
  'ngSanitize'
  'ngStorage'
  'denodeify'
]

# TODO: move to a separate file for root ctrl
require('./_services/chat.service.coffee')
APP
.controller 'RootCtrl',
($scope, AltexoChat, $localStorage) ->
  $scope.$storage = $localStorage.$default {
    nickname: 'Anonymous'
    usedRooms: []
  }
  $scope.rememberRoom = (name) ->
    { usedRooms } = $scope.$storage
    if usedRooms.indexOf(name) != -1
      usedRooms.splice(usedRooms.indexOf(name), 1)
    usedRooms.unshift(name)
    if usedRooms.length > 6
      usedRooms.pop()
    return
  $scope.chat = new AltexoChat()
  return

APP
.factory 'httpRequestInterceptor',
(AuthTokenService) -> {
  request: (config) ->
    unless AuthTokenService.auth_token then config
    else _.extend config, {
      headers: _.defaults {
        'Authorization': "Token #{AuthTokenService.auth_token}"
      } , config.headers
      }
}

require('./_services/auth-token.service.coffee')
require('./_services/storage.service.coffee')
require('./_services/al-rooms.service.coffee')
require('./config.coffee')

##
# Features
#
require('./features/modernizr/index.coffee')
require('./features/video_stream/index.coffee')
require('./features/recently_used_rooms/index.coffee')

# TODO: take a look later and may be move to 'features'
require('./sections/chatroom/web-rtc-view.directive.coffee')

module.exports = APP
