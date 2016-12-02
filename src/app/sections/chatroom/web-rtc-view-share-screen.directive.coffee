require('../../_services/web-rtc-peer.service.coffee')
require('../../_services/screen-sharing-extension.service.coffee')

angular.module('AltexoApp')

.directive 'altexoWebRtcViewShareScreen', ($q, $timeout, WebRtcPeer, ScreenSharingExtension) -> {
  restrict: 'E'
  link: ($scope, $element, attrs) ->
    chat = $scope.$eval(attrs.chat)

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

    ScreenSharingExtension.getStream()
    .then (screenStream) ->
      # toggle back when "Stop sharing" button is pressed
      screenStream.getVideoTracks()[0].onended = ->
        $timeout(0).then ->
          chat.shareScreen = false

      startWebRtc(screenStream, attrs.mode ? 'sendrecv')
    .then null, (error) ->
      if error == 'cancel'
        chat.shareScreen = false
      return $q.reject(error)
    .then (webRtcPeer) ->

      getLocalTrack = (type) ->
        streams = webRtcPeer.peerConnection.getLocalStreams()
        if streams.length
          if (tracks = switch type
                when 'audio' then streams[0].getAudioTracks()
                when 'video' then streams[0].getVideoTracks()
                else []).length
            return tracks[0]
        return null

      webRtcPeer.on 'icecandidate', (candidate) ->
        chat.sendCandidate(candidate)

      endReceivePeerCandidates = chat.$on 'ice-candidate', (candidate) ->
        webRtcPeer.addIceCandidate(candidate)

      $scope.$on '$destroy', ->
        endReceivePeerCandidates()
        webRtcPeer.dispose()

      # Turn on/off tracks when mode changes.
      $scope.$watch "#{attrs.chat}.rpc.mode.audio", (value, prev) ->
        unless value == prev
          if track = getLocalTrack('audio')
            track.enabled = (value == 'on')
        return

      $scope.$watch "#{attrs.chat}.rpc.mode.video", (value, prev) ->
        unless value == prev
          if track = getLocalTrack('video')
            track.enabled = (value == 'webcam') || (value == 'sharedscreen')
        return

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
