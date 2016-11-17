require('../../_services/web-rtc-peer.service.coffee')

angular.module('AltexoApp')

.directive 'altexoWebRtcViewShareScreen', ($window, $q, WebRtcPeer) -> {
  restrict: 'E'
  link: ($scope, $element, attrs) ->
    chat = $scope.$eval(attrs.chat)

    getScreenStream = ->
      $q (resolve, reject) ->
        console.log '>> altexo-web-rtc-view-share-screen: get screen media stream'

        extensionInstalled = false

        handleMessage = (ev) ->
          if ev.origin == $window.location.origin and ev.data
            switch ev.data.type
              when 'SS_PING'
                console.log '>> altexo-web-rtc-view-share-screen: ping ok'
                extensionInstalled = true
              when 'SS_DIALOG_SUCCESS'
                # TODO: checking extension
                # unless extensionInstalled
                #   alert('NO EXTENSION INSTALLED!')
                $window.removeEventListener('message', handleMessage)
                navigator.webkitGetUserMedia({
                  # Requesting audio will fail capturing :(
                  audio: false
                  video: {
                    mandatory: {
                      chromeMediaSource: 'desktop'
                      chromeMediaSourceId: ev.data.streamId
                      maxWidth: $window.screen.width
                      maxHeight: $window.screen.height
                    }
                  }
                }, resolve, reject)
              when 'SS_DIALOG_CANCEL'
                $window.removeEventListener('message', handleMessage)
                reject('cancel')
          return

        $window.addEventListener('message', handleMessage)
        $window.postMessage({
          type: 'SS_UI_REQUEST'
          text: 'start'
          url: $window.location.origin
        }, '*')


    startWebRtc = (videoStream, mode) ->
      console.info '>> altexo-web-rtc-view-share-screen: start', mode

      localVideo = $element.find('video.local').get(0)
      remoteVideo = $element.find('video.remote').get(0)

      switch mode
        when 'sendonly'
          WebRtcPeer.WebRtcPeerSendonly { videoStream, localVideo }
        when 'recvonly'
          WebRtcPeer.WebRtcPeerRecvonly { videoStream, remoteVideo }
        else
          WebRtcPeer.WebRtcPeerSendrecv { videoStream, localVideo, remoteVideo }
          .then null, (error) ->
            console.info '>> altexo-web-rtc-view-share-screen: fallback to recvonly mode'
            WebRtcPeer.WebRtcPeerRecvonly { videoStream, remoteVideo }

    getScreenStream()
    .then (screenStream) ->
      startWebRtc(screenStream, attrs.mode ? 'sendrecv')
    .then (webRtcPeer) ->

      webRtcPeer.on 'icecandidate', (candidate) ->
        chat.sendCandidate(candidate)

      endReceivePeerCandidates = chat.$on 'ice-candidate', (candidate) ->
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
        # watchMuteState('remote', 'video')
        # watchMuteState('remote', 'audio')

      unless chat.isWaiter()
        console.info '>> altexo-web-rtc-view-share-screen: call'

        webRtcPeer.generateOffer()
        .then (offerSdp) ->
          chat.sendOffer(offerSdp)
        .then (answerSdp) ->
          webRtcPeer.processAnswer(answerSdp)
      else
        console.info '>> altexo-web-rtc-view-share-screen: wait call'

        chat.receiveOffer()
        .then (offerSdp) ->
          webRtcPeer.processOffer(offerSdp)
        .then (answerSdp) ->
          chat.sendAnswer(answerSdp)

    .then ->
      console.info '>> altexo-web-rtc-view-share-screen: done'

    .then null, (error) ->
      console.error '>> altexo-web-rtc-view-share-screen:', error

    return
}
