require('../../_services/web-rtc-peer.service.coffee')

angular.module('AltexoApp')

.directive 'altexoWebRtcView', (WebRtcPeer) -> {
  restrict: 'E'
  # template: '<ng-transclude/>'
  # transclude: true
  link: ($scope, $element, attrs) ->
    chat = $scope.$eval(attrs.chat)

    # $scope.iceSent = 0
    # $scope.iceReceived = 0

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
        # $scope.$apply ->
        #   $scope.iceSent = $scope.iceSent + 1
        chat.sendCandidate(candidate)

      endReceivePeerCandidates = chat.$on 'ice-candidate', (candidate) ->
        # $scope.$apply ->
        #   $scope.iceReceived = $scope.iceReceived + 1
        webRtcPeer.addIceCandidate(candidate)

      $scope.$on '$destroy', ->
        endReceivePeerCandidates()
        webRtcPeer.dispose()

      watchMuteState = (local, type) ->
        state = "#{attrs.mediaState}.#{local}.#{type}"
        endWatch = $scope.$watch state, (value, prev) ->
          unless value == prev
            streams = switch local
              when 'local' then webRtcPeer.peerConnection.getLocalStreams()
              when 'remote' then webRtcPeer.peerConnection.getRemoteStreams()
            if streams.length
              tracks = switch type
                when 'audio' then streams[0].getAudioTracks()
                when 'video' then streams[0].getVideoTracks()
              if tracks.length
                tracks[0].enabled = value
          return
        $scope.$on '$destroy', endWatch

      if attrs.mediaState
        watchMuteState('local', 'video')
        watchMuteState('local', 'audio')
        watchMuteState('remote', 'video')
        watchMuteState('remote', 'audio')

      unless chat.isWaiter()
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

    return
}
