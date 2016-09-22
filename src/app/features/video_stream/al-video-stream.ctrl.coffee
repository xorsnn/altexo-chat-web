global.THREE = require('three')
Detector = require('../../../../node_modules/three/examples/js/Detector.js')
# Detector.webgl = false
require('../../../../node_modules/three/examples/js/renderers/CanvasRenderer.js')
require('../../../../node_modules/three/examples/js/renderers/Projector.js')
if DEBUG == 'true'
  Stats = require('../../../../node_modules/three/examples/js/libs/stats.min.js')

class AlVideoStreamController
  ### @ngInject ###
  constructor: ($scope, $element, $timeout) ->

    @webglRenderer = Detector.webgl
    @reflectionShader = {
      frag: require('raw!../../../shaders/reflection.frag')
      vert: require('raw!../../../shaders/reflection.vert')
    }
    @reqAnimFrame = null

    @element = $element[0]

    @AMOUNT = 100

    @container = null
    @stats = null

    @camera = null
    @scene = null
    @renderer = null

    ##
    # Local
    @video = null
    @image = null
    @imageContext = null
    @imageReflection = null
    @imageReflectionContext = null
    @imageReflectionGradient = null
    @texture = null
    @textureReflection = null

    ##
    # Remote
    @remoteVideo = null
    @remoteImage = null
    @remoteImageContext = null
    @remoteImageReflection = null
    @remoteImageReflectionContext = null
    @remoteImageReflectionGradient = null
    @remoteTexture = null
    @remoteTextureReflection = null

    @mesh = null

    @mouseX = 0
    @mouseY = 0

    @windowHalfX = window.innerWidth / 2
    @windowHalfY = window.innerHeight / 2

    ##
    # Local and remote streams
    @localStreaming = false
    @localStreamSize = {
      width: 0
      height: 0
    }
    @remoteStreaming = false
    @remoteStreamSize = {
      width: 0
      height: 0
    }

    $element.ready () =>
      $timeout () =>
        @_init()
        @animate()
      , 0

    $scope.$on '$destroy', () =>
      cancelAnimationFrame(@reqAnimFrame)
      return

    return

  _initRemoteRenderer: () ->
    @remoteStreamSize = @_getRemoteVideoSize()

    #

    @remoteImage = document.createElement( 'canvas' )
    @remoteImage.width = @remoteStreamSize.width
    @remoteImage.height = @remoteStreamSize.height

    @remoteImageContext = @remoteImage.getContext( '2d' )
    @remoteImageContext.fillStyle = '#000000'
    @remoteImageContext.fillRect( 0, 0, @remoteStreamSize.width, @remoteStreamSize.height )

    @remoteTexture = new THREE.Texture( @remoteImage )
    @remoteTexture.minFilter = THREE.LinearFilter

    material = new THREE.MeshBasicMaterial( { map: @remoteTexture, overdraw: 0.5 } )

    materialReflection = null
    unless @webglRenderer
      @remoteImageReflection = document.createElement( 'canvas' )
      @remoteImageReflection.width = @remoteStreamSize.width
      @remoteImageReflection.height = @remoteStreamSize.height

      @remoteImageReflectionContext = @remoteImageReflection.getContext( '2d' )
      @remoteImageReflectionContext.fillStyle = '#000000'
      @remoteImageReflectionContext.fillRect( 0, 0, @remoteStreamSize.width, @remoteStreamSize.height )

      @remoteImageReflectionGradient = @remoteImageReflectionContext.createLinearGradient( 0, 0, 0, @remoteStreamSize.height )
      @remoteImageReflectionGradient.addColorStop( 0.2, 'rgba(240, 240, 240, 1)' )
      @remoteImageReflectionGradient.addColorStop( 1, 'rgba(240, 240, 240, 0.8)' )

      @remoteTextureReflection = new THREE.Texture( @remoteImageReflection )
      @remoteTextureReflection.minFilter = THREE.LinearFilter

      materialReflection = new THREE.MeshBasicMaterial( { map: @remoteTextureReflection, side: THREE.BackSide, overdraw: 0.5 } )
    else
      materialReflection = new THREE.ShaderMaterial({
        uniforms: {
          'map': { value: @remoteTexture }
        }
        vertexShader: @reflectionShader.vert
        fragmentShader: @reflectionShader.frag
        # blending: THREE.AdditiveBlending
        # depthTest: false
        # depthWrite: false
        transparent: true
      } )

    #

    plane = new THREE.PlaneGeometry( 320, 240, 4, 4 )

    @mesh = new THREE.Mesh( plane, material )
    @mesh.position.x = - 320
    @mesh.rotation.y = Math.PI / 6
    @scene.add(@mesh)

    unless @webglRenderer
      @mesh = new THREE.Mesh( plane, materialReflection )
      @mesh.position.y = - 240
      @mesh.position.x = - 320
      @mesh.rotation.y = - Math.PI / 6
      @mesh.rotation.x = - Math.PI
      @scene.add( @mesh )
    else
      @mesh = new THREE.Mesh( plane, materialReflection )
      @mesh.position.y = - 240
      @mesh.position.x = - 320
      @mesh.rotation.y = Math.PI / 6
      @scene.add( @mesh )

    return

  _initLocalRenderer: () ->
    @localStreamSize = @_getLocalVideoSize()

    #

    @image = document.createElement( 'canvas' )
    @image.width = @localStreamSize.width
    @image.height = @localStreamSize.height

    @imageContext = @image.getContext( '2d' )
    @imageContext.fillStyle = '#000000'
    @imageContext.fillRect( 0, 0, @localStreamSize.width, @localStreamSize.height )

    @texture = new THREE.Texture( @image )
    @texture.minFilter = THREE.LinearFilter

    material = new THREE.MeshBasicMaterial( { map: @texture, overdraw: 0.5 } )

    materialReflection = null
    unless @webglRenderer
      @imageReflection = document.createElement( 'canvas' )
      @imageReflection.width = @localStreamSize.width
      @imageReflection.height = @localStreamSize.height

      @imageReflectionContext = @imageReflection.getContext( '2d' )
      @imageReflectionContext.fillStyle = '#000000'
      @imageReflectionContext.fillRect( 0, 0, @localStreamSize.width, @localStreamSize.height )

      @imageReflectionGradient = @imageReflectionContext.createLinearGradient( 0, 0, 0, @localStreamSize.height )
      @imageReflectionGradient.addColorStop( 0.2, 'rgba(240, 240, 240, 1)' )
      @imageReflectionGradient.addColorStop( 1, 'rgba(240, 240, 240, 0.8)' )

      @textureReflection = new THREE.Texture( @imageReflection )
      @textureReflection.minFilter = THREE.LinearFilter

      materialReflection = new THREE.MeshBasicMaterial( {
        map: @textureReflection,
        side: THREE.BackSide,
        overdraw: 0.5
      } )
    else
      materialReflection = new THREE.ShaderMaterial({
        uniforms: {
          'map': { value: @texture }
        }
        vertexShader: @reflectionShader.vert
        fragmentShader: @reflectionShader.frag
        # blending: THREE.AdditiveBlending
        # depthTest: false
        # depthWrite: false
        transparent: true
      } )

    #

    plane = new THREE.PlaneGeometry( 320, 240, 4, 4 )

    @mesh = new THREE.Mesh( plane, material )
    @mesh.position.x = 320
    @mesh.rotation.y = - Math.PI / 6
    @scene.add(@mesh)

    unless @webglRenderer
      @mesh = new THREE.Mesh( plane, materialReflection )
      @mesh.position.y = - 240
      @mesh.position.x = 320
      @mesh.rotation.y = Math.PI / 6
      @mesh.rotation.x = - Math.PI
      @scene.add( @mesh )
    else
      @mesh = new THREE.Mesh( plane, materialReflection )
      @mesh.position.y = - 240
      @mesh.position.x = 320
      @mesh.rotation.y = - Math.PI / 6
      @scene.add( @mesh )

    return

  _init: () ->

    @container = @element

    if DEBUG == 'true'
      info = document.createElement( 'div' )
      info.style.position = 'absolute'
      info.style.top = '10px'
      info.style.width = '100%'
      info.style.textAlign = 'center'
      info.innerHTML = '<a href="https://altexo.com" target="_blank">Altexo</a> demo'

      @container.appendChild( info )

    @camera = new THREE.PerspectiveCamera( 45, @element.offsetWidth / @element.offsetHeight, 1, 10000 )
    @camera.position.z = 1000

    @scene = new THREE.Scene()

    @video = document.getElementById( 'localVideo' )
    @remoteVideo = document.getElementById( 'remoteVideo' )

    #

    separation = 150
    amountx = 10
    amounty = 10


    PI2 = Math.PI * 2

    if @webglRenderer
      material = new THREE.SpriteMaterial({
        color: 0x0808080,
      } )
    else
      material = new THREE.SpriteCanvasMaterial({
        color: 0x0808080,
        program: ( context ) ->
          context.beginPath()
          context.arc( 0, 0, 0.5, 0, PI2, true )
          context.fill()
          return
      } )

    for ix in [0...amountx]
      for iy in [0...amounty]
        particle = new THREE.Sprite( material )
        particle.position.x = ix * separation - ( ( amountx * separation ) / 2 )
        particle.position.y = - 120
        particle.position.z = iy * separation - ( ( amounty * separation ) / 2 )
        particle.scale.x = particle.scale.y = 2
        @scene.add( particle )

    if @webglRenderer
      @renderer = new THREE.WebGLRenderer( { antialias: true } )
    else
      @renderer = new THREE.CanvasRenderer()
    @renderer.setClearColor( 0xf0f0f0 )
    @renderer.setPixelRatio( window.devicePixelRatio )
    @renderer.setSize( @element.offsetWidth, @element.offsetHeight )
    @container.appendChild( @renderer.domElement )

    if DEBUG == 'true'
      @stats = new Stats()
      @container.appendChild( @stats.dom )

    document.addEventListener( 'mousemove', @_onDocumentMouseMove, false )
    window.addEventListener( 'resize', @_onWindowResize, false )
    return

  _onWindowResize: () =>
    console.log 'resize'
    @windowHalfX = @element.offsetWidth / 2
    @windowHalfY = @element.offsetHeight / 2

    @camera.aspect = @element.offsetWidth / @element.offsetHeight
    @camera.updateProjectionMatrix()

    @renderer.setSize( @element.offsetWidth, @element.offsetHeight )

  _onDocumentMouseMove: ( event ) =>
    @mouseX = ( event.clientX - @windowHalfX )
    @mouseY = ( event.clientY - @windowHalfY ) * 0.2

  _getLocalVideoSize: () ->
    return {
      width: @video.videoWidth,
      height: @video.videoHeight
    }

  _getRemoteVideoSize: () ->
    return {
      width: @remoteVideo.videoWidth,
      height: @remoteVideo.videoHeight
    }

  animate: () ->
    @reqAnimFrame = requestAnimationFrame =>
      @animate()

    @camera.position.x += ( @mouseX - @camera.position.x ) * 0.05
    @camera.position.y += ( - @mouseY - @camera.position.y ) * 0.05
    @camera.lookAt( @scene.position )

    unless @localStreaming
      localVideoSize = @_getLocalVideoSize()
      unless localVideoSize.width == 0 or localVideoSize.height == 0
        # consider the strem to be started
        @localStreaming = true
        @_initLocalRenderer()
    else
      if ( @video.readyState == @video.HAVE_ENOUGH_DATA )
        @imageContext.drawImage( @video, 0, 0 )

        if ( @texture )
          @texture.needsUpdate = true

        unless @webglRenderer
          if ( @textureReflection )
            @textureReflection.needsUpdate = true

      unless @webglRenderer
        @imageReflectionContext.drawImage( @image, 0, 0 )
        @imageReflectionContext.fillStyle = @imageReflectionGradient
        @imageReflectionContext.fillRect( 0, 0, @localStreamSize.width, @localStreamSize.height )

    unless @remoteStreaming
      remoteVideoSize = @_getRemoteVideoSize()
      unless remoteVideoSize.width == 0 or remoteVideoSize.height == 0
        # consider the strem to be started
        @remoteStreaming = true
        @_initRemoteRenderer()
    else
      if ( @remoteVideo.readyState == @remoteVideo.HAVE_ENOUGH_DATA )
        @remoteImageContext.drawImage( @remoteVideo, 0, 0 )

        if ( @remoteTexture )
          @remoteTexture.needsUpdate = true

        unless @webglRenderer
          if ( @remoteTextureReflection )
            @remoteTextureReflection.needsUpdate = true

      unless @webglRenderer
        @remoteImageReflectionContext.drawImage( @remoteImage, 0, 0 )
        @remoteImageReflectionContext.fillStyle = @remoteImageReflectionGradient
        @remoteImageReflectionContext.fillRect( 0, 0, @remoteStreamSize.width, @remoteStreamSize.height )

    @renderer.render( @scene, @camera )

    if DEBUG == 'true'
      @stats.update()

    return

module.exports = AlVideoStreamController
