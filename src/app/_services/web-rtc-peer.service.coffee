denodeify = require('denodeify')
{WebRtcPeer} = require('../../../bower_components/kurento-utils/lib')

nodeStyleMethods = [
  'addIceCandidate'
  'generateOffer'
  'processAnswer'
  'processOffer'
]

angular.module('AltexoApp')

.service 'WebRtcPeer', ($q, AL_RTC) -> {
  WebRtcPeerSendrecv: (options) ->
    options.configuration ?= AL_RTC.config
    $q (resolve, reject) ->
      console.debug '>> new WebRtcPeer.SENDRECV', options
      webRtcPeer = new WebRtcPeer.WebRtcPeerSendrecv options, (error) ->
        if error
          return reject(error)
        for method in nodeStyleMethods
          webRtcPeer[method] = denodeify(webRtcPeer[method])
        resolve(webRtcPeer)

  WebRtcPeerSendonly: (options) ->
    options.configuration ?= AL_RTC.config
    $q (resolve, reject) ->
      console.debug '>> new WebRtcPeer.SENDONLY', options
      webRtcPeer = new WebRtcPeer.WebRtcPeerSendonly options, (error) ->
        if error
          return reject(error)
        for method in nodeStyleMethods
          webRtcPeer[method] = denodeify(webRtcPeer[method])
        resolve(webRtcPeer)

  WebRtcPeerRecvonly: (options) ->
    options.configuration ?= AL_RTC.config
    $q (resolve, reject) ->
      console.debug '>> new WebRtcPeer.RECVONLY', options
      webRtcPeer = new WebRtcPeer.WebRtcPeerRecvonly options, (error) ->
        if error
          return reject(error)
        for method in nodeStyleMethods
          webRtcPeer[method] = denodeify(webRtcPeer[method])
        resolve(webRtcPeer)
}
