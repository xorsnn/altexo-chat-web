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

    startWebRtc = (mode) ->
      console.info '>> altexo-web-rtc-view: start', mode

      localVideo = $element.find('video.local').get(0)
      remoteVideo = $element.find('video.remote').get(0)

      switch mode
        when 'sendonly'
          WebRtcPeer.WebRtcPeerSendonly { localVideo }
        when 'recvonly'
          WebRtcPeer.WebRtcPeerRecvonly { remoteVideo }
        else
          WebRtcPeer.WebRtcPeerSendrecv { localVideo, remoteVideo }
          .then null, (error) ->
            console.info '>> altexo-web-rtc-view: fallback to recvonly mode'
            WebRtcPeer.WebRtcPeerRecvonly { remoteVideo }

    startWebRtc(attrs.mode ? 'sendrecv')
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
        $scope.$watch "#{attrs.mediaState}.#{local}.#{type}", (value, prev) ->
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
