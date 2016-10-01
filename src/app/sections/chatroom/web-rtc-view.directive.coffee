require('../../_services/web-rtc-peer.service.coffee')

angular.module('AltexoApp')

.directive 'altexoWebRtcView', (WebRtcPeer, $routeParams, AuthTokenService, AlRoomsService) -> {
  restrict: 'E'
  template: '<ng-transclude/>'
  transclude: true
  link: ($scope, $element, attrs) ->
    chat = $scope.$eval(attrs.chat)
    # add room to used
    AlRoomsService.roomUsed($routeParams.room)

    # TODO: untill kurento configured consider allways p2p
    # waitCall = $scope.$eval(attrs.waitCall ? 'false')
    vm = this
    vm.waitCall = true

    $scope.iceSent = 0
    $scope.iceReceived = 0

    alJoin = =>
      (switch (attrs.mode ? 'sendrecv')
        when 'sendonly'
          console.info '>> altexo-web-rtc-view: send only'
          WebRtcPeer.WebRtcPeerSendonly {
            localVideo: document.getElementById( 'localVideo' )
          }
        when 'recvonly'
          console.info '>> altexo-web-rtc-view: receive only'
          WebRtcPeer.WebRtcPeerRecvonly {
            remoteVideo: document.getElementById( 'remoteVideo' )
          }
        else
          console.info '>> altexo-web-rtc-view: send/receive'
          WebRtcPeer.WebRtcPeerSendrecv {
            localVideo: document.getElementById( 'localVideo' )
            remoteVideo: document.getElementById( 'remoteVideo' )
          }
          .then null, (error) ->
            console.error '>> altexo-web-rtc-view:', error
            console.info '>> altexo-web-rtc-view: fallback to receive only mode'
            WebRtcPeer.WebRtcPeerRecvonly {
              remoteVideo: document.getElementById( 'remoteVideo' )
            } )
      .then (webRtcPeer) ->

        webRtcPeer.on 'icecandidate', (candidate) ->
          $scope.$apply ->
            $scope.iceSent = $scope.iceSent + 1
          chat.sendCandidate(candidate)

        endReceivePeerCandidates = chat.$on 'ice-candidate', (candidate) ->
          $scope.$apply ->
            $scope.iceReceived = $scope.iceReceived + 1
          webRtcPeer.addIceCandidate(candidate)

        $scope.$on '$destroy', ->
          endReceivePeerCandidates()
          webRtcPeer.dispose()

        unless vm.waitCall
          console.info '>> altexo-web-rtc-view: call'

          webRtcPeer.generateOffer()
          .then (offerSdp) ->
            chat.sendOffer(offerSdp)
          .then (answerSdp) ->
            webRtcPeer.processAnswer(answerSdp)
        else
          console.info '>> altexo-web-rtc-view: wait call'

          chat.receiveOffer()
          .then (offerSdp) ->
            webRtcPeer.processOffer(offerSdp)
          .then (answerSdp) ->
            chat.sendAnswer(answerSdp)

      .then ->
        console.info '>> altexo-web-rtc-view: done'

      .then null, (error) ->
        console.error '>> altexo-web-rtc-view:', error


    # TODO: add room existence check here
    chat.ensureOpen()
    .then -> chat.enterRoom($routeParams.room)
    .then (res) ->
      # TODO: handle leaving room on closing
      # $scope.$on '$destroy', ->
      #   $scope.chat.leaveRoom()

      # NOTE: consider room exists, trying to enter
      vm.waitCall = false
      alJoin()
    , (err) ->
      # NOTE: the room doesn't exist, let's create one
      # TODO 1003 - code for 'room is not found' error, move to constants
      if err.code == 1003
        chat.ensureOpen()
        .then -> chat.authenticate(AuthTokenService.auth_token)
        .then -> chat.createRoom($routeParams.room, true) # NOTE: hardcoded p2p
        .then -> alJoin()

    return
}
