THREE = require('three')

angular.module('AltexoApp')
.service 'AlWebVR', (VR_STATE) ->

  state = VR_STATE.UNKNOWN_VR_STATE
  display =  undefined
  canvas = undefined

  AlWebVR = {
    init: () ->
      if ( navigator.getVRDisplays != undefined )
        navigator.getVRDisplays().then( ( displays ) ->
          if ( displays.length == 0 )
            state = VR_STATE.NO_VR_DISPLAY
          else
            display = displays[ 0 ]
            state = VR_STATE.VR_AVALIABLE
        )
      else
        state = VR_STATE.VR_NOT_SUPPORTED
      return

    isVRAvaliable: () ->
      state == VR_STATE.VR_AVALIABLE

    getVRDisplay: () ->
      display

    getVRBtnTooltip: () ->
      if state == VR_STATE.VR_NOT_SUPPORTED
        'Your browser does not support WebVR. See https://webvr.info for assistance.'
      else if state == VR_STATE.NO_VR_DISPLAY
        'WebVR supported, but no VRDisplays found.'
      else if state == VR_STATE.VR_AVALIABLE
        'Switch to VR display'
      else
        'Loading...'

    setCanvas: (newCanvas) ->
      canvas = newCanvas
      return

    switchToVR: () ->
      if display and canvas
        if display.isPresenting
          display.exitPresent()
        else
          display.requestPresent( [ { source: canvas } ] )
      return
  }
