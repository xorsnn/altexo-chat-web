
angular.module('AltexoApp')

.service 'ScreenSharingExtension', ($window, $q) ->
  extensionInstalled = false

  checkExtension = (ev) ->
    if ev.origin == $window.location.origin and ev.data
      if ev.data.type == 'SS_PING'
        $window.removeEventListener('message', checkExtension)
        $window.postMessage({
          type: 'SS_UI_PONG'
          url: $window.location.origin
        }, '*')
        extensionInstalled = true
    return

  $window.addEventListener('message', checkExtension)

  return {
    isAvailable: -> $window.navigator.userAgent.indexOf('Chrome') != -1

    isInstalled: -> extensionInstalled

    getStream: ->
      $q (resolve, reject) ->
        unless extensionInstalled
          return reject('no extension')

        handleMessage = (ev) ->
          if ev.origin == $window.location.origin and ev.data
            switch ev.data.type
              when 'SS_DIALOG_SUCCESS'
                $window.removeEventListener('message', handleMessage)
                getUserMedia({
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
  }
