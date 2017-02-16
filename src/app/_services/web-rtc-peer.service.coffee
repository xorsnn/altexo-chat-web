denodeify = require('denodeify')
{WebRtcPeer} = require('../../../bower_components/kurento-utils/lib')

nodeStyleMethods = [
  'addIceCandidate'
  'generateOffer'
  'processAnswer'
  'processOffer'
]

angular.module('AltexoApp')

.service 'WebRtcPeer', ($q) -> {
  WebRtcPeerSendrecv: (options) ->
    $q (resolve, reject) ->
      webRtcPeer = new WebRtcPeer.WebRtcPeerSendrecv options, (error) ->
        if error
          return reject(error)
        for method in nodeStyleMethods
          webRtcPeer[method] = denodeify(webRtcPeer[method])
        resolve(webRtcPeer)

  WebRtcPeerSendonly: (options) ->
    $q (resolve, reject) ->
      webRtcPeer = new WebRtcPeer.WebRtcPeerSendonly options, (error) ->
        if error
          return reject(error)
        for method in nodeStyleMethods
          webRtcPeer[method] = denodeify(webRtcPeer[method])
        resolve(webRtcPeer)

  WebRtcPeerRecvonly: (options) ->
    $q (resolve, reject) ->
      webRtcPeer = new WebRtcPeer.WebRtcPeerRecvonly options, (error) ->
        if error
          return reject(error)
        for method in nodeStyleMethods
          webRtcPeer[method] = denodeify(webRtcPeer[method])
        resolve(webRtcPeer)
}
