

_nodeStyleMethods = [
  'addIceCandidate'
  'generateOffer'
  'processAnswer'
  'processOffer'
]

angular.module('AltexoApp')

.service 'WebRtcPeer', ($q, denodeify) -> {
  WebRtcPeerSendrecv: (options) ->
    $q (resolve, reject) ->
      webRtcPeer = new kurentoUtils.WebRtcPeer.WebRtcPeerSendrecv options, (error) ->
        if error
          return reject(error)
        for method in _nodeStyleMethods
          webRtcPeer[method] = denodeify(webRtcPeer[method])
        resolve(webRtcPeer)

  WebRtcPeerSendonly: (options) ->
    $q (resolve, reject) ->
      webRtcPeer = new kurentoUtils.WebRtcPeer.WebRtcPeerSendonly options, (error) ->
        if error
          return reject(error)
        for method in _nodeStyleMethods
          webRtcPeer[method] = denodeify(webRtcPeer[method])
        resolve(webRtcPeer)

  WebRtcPeerRecvonly: (options) ->
    $q (resolve, reject) ->
      webRtcPeer = new kurentoUtils.WebRtcPeer.WebRtcPeerRecvonly options, (error) ->
        if error
          return reject(error)
        for method in _nodeStyleMethods
          webRtcPeer[method] = denodeify(webRtcPeer[method])
        resolve(webRtcPeer)
}
