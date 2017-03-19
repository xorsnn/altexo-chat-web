THREE = require('three')

AlRgbRenderer = require './al-rgb-renderer.class.coffee'
AlSoundRenderer = require './al-sound-renderer.class.coffee'
AlHologramRenderer = require './al-hologram-renderer.class.coffee'
AlLabel = require './al-label.class.coffee'
FullscreenRenderer = require './fullscreen-renderer.class.coffee'

{ NO_VIDEO, DEPTH_VIDEO, RGB_VIDEO,
  ICOSAHEDRON_RADIUS,
  SURFACE_DISTANCE_KOEFFICIENT } = require './al-video-stream.const.coffee'

class AlAvatar
  rgbRenderer: null
  hologramRenderer: null
  soundRenderer: null
  labelRenderer: null
  fullscreenRenderer: null

  streaming: false
  view: 'regular'

  renderer: null

  rendererData: null
  seat: null
  source: null

  scene: null
  camera: null
  video: null

  IDENT_NAMES = (require 'lodash').shuffle [
    'Cheech', 'Chong', 'Goofy', 'Psyduck', 'Crabs'
  ]

  constructor: ->
    IDENT = IDENT_NAMES.shift() ? "#{Math.floor(Math.random()*1e3)}"
    Object.defineProperty @, 'IDENT', {
      get: => "** #{IDENT.toUpperCase()} [#{@labelRenderer?.labelText}] **"
    }

    @seat = {
      place: 0
      total: 0
    }

    @source = {
      dx: 0
      dy: 0
      width: 0
      height: 0
    }

    @rendererData = {
      video: null
      image: null
      imageContext: null
      imageReflection: null
      imageReflectionContext: null
      imageReflectionGradient: null
      texture: null
      textureReflection: null
      modification: {
        rotation: {
          x: 0
          y: seat(0, false).angle
          z: 0
        }
        position: {
          x: seat(0, false).x
          y: seat(0, false).y
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
          video: RGB_VIDEO
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
            x: seat(0, false).x
            # surface coordinate - 120
            y: ICOSAHEDRON_RADIUS + ICOSAHEDRON_RADIUS * SURFACE_DISTANCE_KOEFFICIENT
            z: 0
          }
        }
      }
    }

  bind: ({ @scene, @camera, @video }) ->
    console.debug '>> BIND AVATAR', @IDENT, this

    @soundRenderer = new AlSoundRenderer(@rendererData, @scene)
    @labelRenderer = new AlLabel(@rendererData, @scene)
    @labelRenderer.showLabel(false)

    @rgbRenderer = new AlRgbRenderer()
    @fullscreenRenderer = new FullscreenRenderer()

    videoReady(this.video).then =>
      console.debug '>> BIND.THEN', @IDENT, this

      { videoWidth, videoHeight } = @video
      if videoWidth == 0 or videoHeight == 0
        throw new Error('AltexoAvatar: empty input')

      # consider the strem to be started
      @labelRenderer.showLabel(true)

      @rendererData.image = document.createElement( 'canvas' )
      @rendererData.image.width = videoWidth
      @rendererData.image.height = videoHeight

      @rendererData.imageContext = @rendererData.image.getContext( '2d' )
      @rendererData.imageContext.fillStyle = '#000000'
      @rendererData.imageContext.fillRect( 0, 0, videoWidth, videoHeight )

      @rendererData.texture = new THREE.Texture( @rendererData.image )
      @rendererData.texture.minFilter = THREE.LinearFilter
      @rendererData.texture.magFilter = THREE.LinearFilter

      @rgbRenderer.setTexture(@rendererData.texture)
      .setXPosition(@rendererData.modification.position.x)
      .setYPosition(@rendererData.modification.position.y)
      .setYRotation(@rendererData.modification.rotation.y)

      @hologramRenderer = new AlHologramRenderer(@rendererData, @scene)

      @fullscreenRenderer.setTexture(@rendererData.texture)

      # Update view. Set renderer
      @streaming = true
      @setView(@view).setSource(@seat)

    @

  unbind: ->
    console.debug '>> UNBIND', this

    @labelRenderer.unbind()
    @labelRenderer = null

    @renderer?.unbind()
    @renderer = null

    @soundRenderer = null
    @fullscreenRenderer = null
    @rgbRenderer = null
    @hologramRenderer = null

    @

  updateTexture: ->
    # @rendererData.imageContext.fillRect(0, 0, @video.videoWidth, @video.videoHeight)
    @rendererData.imageContext.drawImage(@video, @source.dx, @source.dy,
      @source.width, @source.height, 0, 0, @video.videoWidth, @video.videoHeight)
    @rendererData.texture?.needsUpdate = true
    @

  render: ->
    @renderer?.render(@)
    @

  setSource: ({ place, total }) ->
    console.debug '>> SOURCE', @IDENT, place, total

    @seat.place = place
    @seat.total = total
    if total == 1
      @source = {
        dx: 0
        dy: 0
        width: @video.videoWidth
        height: @video.videoHeight
      }
    else if total == 2
      @source = {
        dx: place * (@video.videoWidth >> 1)
        dy: (@video.videoHeight >> 2)
        width: (@video.videoWidth >> 1)
        height: (@video.videoHeight >> 1)
      }
    else if total == 3 or total == 4
      m = place % 2 # column
      n = (place - m) / 2 # row
      @source = {
        dx: m * (@video.videoWidth >> 1)
        dy: n * (@video.videoHeight >> 1)
        width: (@video.videoWidth >> 1)
        height: (@video.videoHeight >> 1)
      }
    @

  setSeat: (n, xs) ->
    console.debug '>> SEAT', @IDENT, n, xs

    _seat = seat(n, xs)

    this.rendererData.modification.rotation.y = _seat.angle
    this.rendererData.modification.position.x = _seat.x
    this.rendererData.modification.position.y = _seat.y
    this.rendererData.sound.modification.position.x = _seat.x

    @

  setSpectrum: (spec) ->
    if @soundRenderer
      @soundRenderer.setSpectrum(spec)
    @

  setLabel: (newLabel) ->
    console.debug '>> LABEL', @IDENT, newLabel

    if @labelRenderer
      @labelRenderer.updateText(newLabel)
    @

  setMode: ({ video }) ->
    console.debug '>> MODE', @IDENT, video

    if video == RGB_VIDEO
      @setView('regular')
    else if video == DEPTH_VIDEO
      @setView('hologram')
    else if video == NO_VIDEO
      @setView('icosahedron')

    @

  setView: (name) ->
    console.debug '>> VIEW', @IDENT, name
    @view = name
    @renderer?.unbind()
    switch name
      when 'regular'
        if @streaming
          @renderer = @rgbRenderer.bind(@)
      when 'fullscreen'
        if @streaming
          @renderer = @fullscreenRenderer.bind(@)
      when 'hologram'
        if @streaming
          @renderer = @hologramRenderer
          @renderer.bind()
      when 'icosahedron'
        @renderer = @soundRenderer
        @renderer.bind()
    @

  setFullscreen: (value) ->
    if value
      if @view == 'regular'
        @setView('fullscreen')
    else
      if @view == 'fullscreen'
        @setView('regular')
    @

  objectsClicked: (intersects) ->
    if @view == 'regular'
      if @renderer.isIntersected(intersects)
        console.debug '>> TOGGLE:', 'fullscreen'
        @setView('fullscreen')
    if @view == 'fullscreen'
      if @renderer.isIntersected(intersects)
        console.debug '>> TOGGLE:', 'regular'
        @setView('regular')
    @

  # some private methods
  # videoReady = (video) -> new Promise (resolve) ->
  #   checkResolve = ->
  #     console.debug '>> WAIT VIDEO', video, video.readyState
  #     if video.readyState == HTMLMediaElement.HAVE_ENOUGH_DATA
  #       resolve(true)
  #     else
  #       setTimeout(checkResolve, 1000)
  #     return
  #   return checkResolve()

  videoReady = (video) ->
    console.debug '>> WAIT VIDEO', video, video.readyState
    if video.readyState == HTMLMediaElement.HAVE_ENOUGH_DATA
      return Promise.resolve(true)
    return new Promise (resolve) ->
      _once = ->
        console.debug '>> WAIT VIDEO', video, video.readyState
        video.removeEventListener('canplaythrough', _once)
        resolve(true)
      video.addEventListener('canplaythrough', _once)

  seat = (k, xs) ->
    if k == 0
      if xs
        return {
          x: 80
          y: -240
          angle: -Math.PI / 6
        }
      else
        return {
          x: 320
          y: -240
          angle: -Math.PI / 6
        }
    if k == 1
      if xs
        return {
          x: -80
          y: -240
          angle: Math.PI / 6
        }
      else
        return {
          x: -320
          y: -240
          angle: Math.PI / 6
        }
    return {
      x: 0
      y: -240
      angle: 0
    }

module.exports = AlAvatar
