
AlRgbRenderer = require './al-rgb-renderer.class.coffee'
AlSoundRenderer = require './al-sound-renderer.class.coffee'
AlHologramRenderer = require './al-hologram-renderer.class.coffee'
AlLabel = require './al-label.class.coffee'

class AlAvatar
  rgbRenderer: null
  hologramRenderer: null
  soundRenderer: null
  labelRenderer: null

  streaming: false

  constructor: (@rendererData, @scene, @video) ->
    console.log "al avatar constructor"
    @soundRenderer = new AlSoundRenderer(@rendererData, @scene)
    @labelRenderer = new AlLabel(@rendererData, @scene)
    return

  _init: () =>
    console.log 'init'
    @rendererData.image = document.createElement( 'canvas' )
    @rendererData.image.width = @rendererData.streamSize.width
    @rendererData.image.height = @rendererData.streamSize.height

    @rendererData.imageContext = @rendererData.image.getContext( '2d' )
    @rendererData.imageContext.fillStyle = '#000000'
    @rendererData.imageContext.fillRect( 0, 0, @rendererData.streamSize.width, @rendererData.streamSize.height )

    @rendererData.texture = new THREE.Texture( @rendererData.image )
    @rendererData.texture.minFilter = THREE.LinearFilter
    @rendererData.texture.magFilter = THREE.LinearFilter

    return

  _getVideoSize: () ->
    return {
      width: @video.videoWidth,
      height: @video.videoHeight
    }

  updateMode: () =>
    if @rgbRenderer
      @rgbRenderer.updateVisibility(@rendererData.streamMode.mode.video)
    if @soundRenderer
      @soundRenderer.updateVisibility(@rendererData.streamMode.mode.video)
    if @hologramRenderer
      @hologramRenderer.updateVisibility(@rendererData.streamMode.mode.video)

  animate: () =>
    if !!@rendererData.streamMode
      if @rendererData.streamMode.mode.video == AL_VIDEO_CONST.RGB_VIDEO or
      @rendererData.streamMode.mode.video == AL_VIDEO_CONST.DEPTH_VIDEO
        unless @streaming
          videoSize = @_getVideoSize()
          unless videoSize.width == 0 or videoSize.height == 0
            @rendererData.streamSize.width = videoSize.width
            @rendererData.streamSize.height = videoSize.height
            # consider the strem to be started
            @streaming = true
            @_init()
            @rgbRenderer = new AlRgbRenderer(this)
            @hologramRenderer = new AlHologramRenderer(@rendererData, @scene)
            @updateMode()

        else
          if ( @video.readyState == @video.HAVE_ENOUGH_DATA )
            @rendererData.imageContext.drawImage( @video, 0, 0 )
            if ( @rendererData.texture )
              @rendererData.texture.needsUpdate = true

      else if @rendererData.streamMode.mode.video == AL_VIDEO_CONST.NO_VIDEO
        @soundRenderer.animate()

    return

  setSpectrum: (spec) =>
    if @soundRenderer
      @soundRenderer.setSpectrum(spec)

    return


module.exports = AlAvatar
