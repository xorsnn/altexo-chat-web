
AlRgbRenderer = require './al-rgb-renderer.class.coffee'
AlSoundRenderer = require './al-sound-renderer.class.coffee'
AlHologramRenderer = require './al-hologram-renderer.class.coffee'
AlLabel = require './al-label.class.coffee'

AL_VIDEO_VIS = require './al-video-stream.const.coffee'


class AlAvatar
  rgbRenderer: null
  hologramRenderer: null
  soundRenderer: null
  labelRenderer: null

  streaming: false

  rendererData: null

  Seat = {
    getXOffset: (k) ->
      switch k
        when 0 then 320
        when 1 then -320
        else 0
    getYOffset: (k) -> -240
    getRotationAngle: (k) ->
      switch k
        when 0 then - Math.PI / 6
        when 1 then Math.PI / 6
        else 0
  }

  videoReady = (video) ->
    if video.readyState == HTMLMediaElement.HAVE_ENOUGH_DATA
      return Promise.resolve(true)
    return new Promise (resolve) ->
      _once = ->
        video.removeEventListener('canplaythrough', _once)
        resolve()
      video.addEventListener('canplaythrough', _once)

  constructor: ->
    this.rendererData = {
      video: null
      image: null
      imageContext: null
      imageReflection: null
      imageReflectionContext: null
      imageReflectionGradient: null
      texture: null
      textureReflection: null
      streamSize: {
        width: 0
        height: 0
      }
      modification: {
        rotation: {
          x: 0
          y: Seat.getRotationAngle(0)
          z: 0
        }
        position: {
          x: Seat.getXOffset(0)
          y: Seat.getYOffset(0)
          z: 0
        }
      }
      mesh: {
        original: null
        reflection: null
        soundViz: null
        soundVizReflection: null
      }
      # FIXME: default values store in localStorage
      streamMode: {
        mode: {
          video: AL_VIDEO_VIS.RGB_VIDEO
          audio: true
        }
      }
      sound: {
        modification: {
          rotation: {
            x: 0
            y: - Math.PI / 6
            z: 0
          }
          position: {
            x: Seat.getXOffset(0)
            # surface coordinate - 120
            y: (AL_VIDEO_VIS.ICOSAHEDRON_RADIUS +
              (AL_VIDEO_VIS.ICOSAHEDRON_RADIUS * AL_VIDEO_VIS.SURFACE_DISTANCE_KOEFFICIENT))
            z: 0
          }
        }
      }
    }

  bind: ({ @scene, @camera, @video }) ->
    @soundRenderer = new AlSoundRenderer(@rendererData, @scene)
    @labelRenderer = new AlLabel(@rendererData, @scene)
    @labelRenderer.showLabel(false)

    videoReady(this.video).then =>
      videoSize = {
        width: @video.videoWidth
        height: @video.videoHeight
      }

      if videoSize.width == 0 or videoSize.height == 0
        throw new Error('AltexoAvatar: empty input')

      @streaming = true

      @rendererData.streamSize.width = videoSize.width
      @rendererData.streamSize.height = videoSize.height
      # consider the strem to be started
      @labelRenderer.showLabel(true)

      @rendererData.image = document.createElement( 'canvas' )
      @rendererData.image.width = @rendererData.streamSize.width
      @rendererData.image.height = @rendererData.streamSize.height

      @rendererData.imageContext = @rendererData.image.getContext( '2d' )
      @rendererData.imageContext.fillStyle = '#000000'
      @rendererData.imageContext.fillRect( 0, 0, @rendererData.streamSize.width, @rendererData.streamSize.height )

      @rendererData.texture = new THREE.Texture( @rendererData.image )
      @rendererData.texture.minFilter = THREE.LinearFilter
      @rendererData.texture.magFilter = THREE.LinearFilter

      @rgbRenderer = new AlRgbRenderer(this, @camera)
      @hologramRenderer = new AlHologramRenderer(@rendererData, @scene)
      @setView()

    @

  unbind: ->
    @labelRenderer.unbind()
    @labelRenderer = null

    @soundRenderer.unbind()
    @soundRenderer = null

    @rgbRenderer?.unbind()
    @rgbRenderer = null

    @hologramRenderer?.unbind()
    @hologramRenderer = null

    @

  render: ->
    if @streaming
      videoMode = @rendererData.streamMode.mode.video

      if ( videoMode == AL_VIDEO_CONST.RGB_VIDEO ||
          videoMode == AL_VIDEO_CONST.DEPTH_VIDEO )
        if ( @video.readyState == @video.HAVE_ENOUGH_DATA )
          @rendererData.imageContext.drawImage( @video, 0, 0 )
          if ( @rendererData.texture )
            @rendererData.texture.needsUpdate = true
        @rgbRenderer.animate()
      else if videoMode == AL_VIDEO_CONST.NO_VIDEO
        @soundRenderer.animate()
    @

  setSeat: (n) ->
    this.rendererData.modification.rotation.y = Seat.getRotationAngle(n)
    this.rendererData.modification.position.x = Seat.getXOffset(n)
    this.rendererData.modification.position.y = Seat.getYOffset(n)
    this.rendererData.sound.modification.position.x = Seat.getXOffset(n)
    @

  setSpectrum: (spec) ->
    if @soundRenderer
      @soundRenderer.setSpectrum(spec)
    @

  setLabel: (newLabel) ->
    if @labelRenderer
      @labelRenderer.updateText(newLabel)
    @

  # rgb|hologram|icosahedron
  #setView: (name) ->
  setView: (newMode) ->
    if newMode?
      @rendererData.streamMode.mode = newMode
    if @rgbRenderer
      @rgbRenderer.updateVisibility(@rendererData.streamMode.mode.video)
    if @soundRenderer
      @soundRenderer.updateVisibility(@rendererData.streamMode.mode.video)
    if @hologramRenderer
      @hologramRenderer.updateVisibility(@rendererData.streamMode.mode.video)
    @

  objectsClicked: (intersects) ->
    if @rgbRenderer
      for intersect in intersects
        if @rendererData.mesh.original == intersect.object
          @rgbRenderer.toggleFullscreen()
    @


module.exports = AlAvatar
