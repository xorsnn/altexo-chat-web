require('../../_services/web-rtc-peer.service.coffee')

getLocalTrack = (webRtcPeer, type) ->
  streams = webRtcPeer.peerConnection.getLocalStreams()
  if streams.length
    if (tracks = switch type
          when 'audio' then streams[0].getAudioTracks()
          when 'video' then streams[0].getVideoTracks()
          else []).length
      return tracks[0]
  return null

angular.module('AltexoApp')

.directive 'altexoWebRtcView', ($q, WebRtcPeer, ScreenSharingExtension) -> {
  restrict: 'E'
  # template: '<ng-transclude/>'
  # transclude: true
  link: ($scope, $element, attrs) ->
    chat = $scope.$eval(attrs.chat)
    shareScreen = chat.rpc.mode.video == 'sharedscreen'

    startWebRtc = ->
      localVideo = $element.find('video.local').get(0)
      remoteVideo = $element.find('video.remote').get(0)

      console.info '>> altexo-web-rtc-view: start sendrecv'
      WebRtcPeer.WebRtcPeerSendrecv { localVideo, remoteVideo }
      .then null, (error) ->
        console.info '>> altexo-web-rtc-view: fallback to recvonly mode'
        WebRtcPeer.WebRtcPeerRecvonly { remoteVideo }

    startScreenSharing = ->
      localVideo = $element.find('video.local').get(0)
      remoteVideo = $element.find('video.remote').get(0)

      console.info '>> altexo-web-rtc-view: start screen sharing'
      ScreenSharingExtension.getStream()
      .then (videoStream) ->
        # toggle back when "Stop sharing" button is pressed
        videoStream.getVideoTracks()[0].onended = ->
          unless chat.isRestarting()
            chat.toggleShareScreen(false)
        # start WebRtcPeer, fallback to receive only when sendrecv fails
        WebRtcPeer.WebRtcPeerSendrecv { videoStream, localVideo, remoteVideo }
        .then null, (error) ->
          WebRtcPeer.WebRtcPeerRecvonly { videoStream, remoteVideo }
      .then null, (error) ->
        if error == 'cancel'
          chat.toggleShareScreen(false)
        return $q.reject(error)

    (if shareScreen then startScreenSharing() else startWebRtc())
    .then (webRtcPeer) ->

      # Exchange candidates.
      webRtcPeer.on 'icecandidate', (candidate) ->
        chat.sendCandidate(candidate)

      endReceivePeerCandidates = chat.$on 'ice-candidate', (candidate) ->
        webRtcPeer.addIceCandidate(candidate)

      # Turn on/off tracks when mode changes.
      $scope.$watch "#{attrs.chat}.rpc.mode.audio", (value, prev) ->
        unless value == prev
          if track = getLocalTrack(webRtcPeer, 'audio')
            track.enabled = (value == 'on')
        return

      $scope.$watch "#{attrs.chat}.rpc.mode.video", (value, prev) ->
        unless value == prev
          if track = getLocalTrack(webRtcPeer, 'video')
            track.enabled = (value == 'webcam') || (value == 'sharedscreen')
        return

      # Clean up.
      $scope.$on '$destroy', ->
        endReceivePeerCandidates()
        webRtcPeer.dispose()

      # Notify model about ready state.
      chat.signalWebRtcReady()

      # Connect with peer.
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
