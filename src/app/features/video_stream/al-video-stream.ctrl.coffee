global.THREE = require('three')
Detector = require('../../../../node_modules/three/examples/js/Detector.js')
# Detector.webgl = false
require('../../../../node_modules/three/examples/js/renderers/CanvasRenderer.js')
require('../../../../node_modules/three/examples/js/renderers/Projector.js')
if DEBUG == 'true'
  Stats = require('../../../../node_modules/three/examples/js/libs/stats.min.js')

global.p5 = require('p5')
sylvester = require('sylvester')
for attrname in Object.keys(sylvester)
  global[attrname] = sylvester[attrname]

require('../../../../node_modules/p5/lib/addons/p5.dom.js')
require('../../../../node_modules/p5/lib/addons/p5.sound.js')

class AlVideoStreamController
  ICOSAHEDRON_RADIUS: 120
  SURFACE_Y: - 120
  SURFACE_DISTANCE_KOEFFICIENT: 0.4

  ### @ngInject ###
  constructor: ($scope, $element, $timeout, $rootScope) ->

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
    @localRendererData = {
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
          y: - Math.PI / 6
          z: 0
        }
        position: {
          x: 320
          y: - 240
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
          video: '2d',
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
            x: 320
            y: @ICOSAHEDRON_RADIUS + (@ICOSAHEDRON_RADIUS * @SURFACE_DISTANCE_KOEFFICIENT) # surface coordinate - 120
            z: 0
          }
        }
      }
    }

    ##
    # Remote
    @remoteRendererData = {
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
          y: Math.PI / 6
          z: 0
        }
        position: {
          x: - 320
          y: - 240
          z: 0
        }
      }
      mesh: {
        original: null
        reflection: null
        soundViz: null
        soundVizReflection: null
      }
      streamMode: null
      sound: {
        modification: {
          rotation: {
            x: 0
            y: - Math.PI / 6
            z: 0
          }
          position: {
            x: - 320
            y: @ICOSAHEDRON_RADIUS + (@ICOSAHEDRON_RADIUS * @SURFACE_DISTANCE_KOEFFICIENT) # surface coordinate - 120
            z: 0
          }
        }
      }
    }

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

    # ANALYZE MIC INPUT
    @spectrum = []
    for i in [0...12]
      @spectrum.push(1)

    mic = new p5.AudioIn()
    mic.start()
    @fft = new p5.FFT(0.8, 16)
    @fft.setInput(mic)

    @visualisatorMaterial = null
    @visualisatorReflectionMaterial = null
    # @icosahedronMesh = null
    # @icosahedronReflectionMesh = null


    $element.ready () =>
      $timeout () =>
        @_init()
        @animate()
      , 0

    $scope.$on '$destroy', () =>
      cancelAnimationFrame(@reqAnimFrame)
      return

    $rootScope.$on 'al-mode-change', (event, data) =>
      @remoteRendererData.streamMode = data.remote
      @localRendererData.streamMode = data.local
      if @remoteRendererData.streamMode
        @_updateRemoteMode()
      if @localRendererData.streamMode
        @_updateLocalMode()
      return

    return

  _initSoundVisualizator: (rendererData) =>
    unless @visualisatorMaterial
      @visualisatorMaterial = new THREE.ShaderMaterial({
        uniforms:
          spectrum: { type: 'fv1', value: @spectrum }
          distanceK: { type: 'f', value: @SURFACE_DISTANCE_KOEFFICIENT}
        vertexShader: require('raw!./shaders/icosahedron.vert')
        fragmentShader: require('raw!./shaders/icosahedron.frag')
        wireframe: true
        side: THREE.DoubleSide
        transparent: true
      } )

    geometry = new THREE.IcosahedronGeometry(@ICOSAHEDRON_RADIUS, 0)

    # NOTE: using unindexed vertices
    indexList = []
    for i in [0...(20 * 3) ]
      indexList.push(i)

    index = new Uint16Array( indexList )

    specList = []
    for face in geometry.faces
      specList.push(face.a)
      specList.push(face.b)
      specList.push(face.c)

    spec = new Float32Array( specList )

    bufferGeometry = new THREE.BufferGeometry()
    bufferGeometry.fromGeometry(geometry)
    bufferGeometry.setIndex( new THREE.BufferAttribute( index, 1 ) )
    bufferGeometry.addAttribute( 'alFFTIndex', new THREE.BufferAttribute( spec, 1 ) )

    rendererData.mesh.soundViz = new THREE.Mesh(
      bufferGeometry,
      @visualisatorMaterial
    )

    rendererData.mesh.soundViz.position.x = rendererData.sound.modification.position.x
    rendererData.mesh.soundViz.position.y = @SURFACE_Y + rendererData.sound.modification.position.y
    # FIXME: remove if nessesary
    # @scene.add( rendererData.mesh.soundViz )

    unless @visualisatorReflectionMaterial
      @visualisatorReflectionMaterial = new THREE.ShaderMaterial({
        uniforms:
          icosahedronRadius: {type: 'f', value: @ICOSAHEDRON_RADIUS}
          centerY: {type: 'f', value: @SURFACE_Y - rendererData.sound.modification.position.y}
          spectrum: { type: 'fv1', value: @spectrum }
          distanceK: { type: 'f', value: @SURFACE_DISTANCE_KOEFFICIENT}
        vertexShader: require('raw!./shaders/icosahedron_reflection.vert')
        fragmentShader: require('raw!./shaders/icosahedron_reflection.frag')
        wireframe: true
        side: THREE.DoubleSide
        transparent: true
      } )

    rendererData.mesh.soundVizReflection = new THREE.Mesh(
      bufferGeometry,
      @visualisatorReflectionMaterial
    )

    rendererData.mesh.soundVizReflection.position.x = rendererData.sound.modification.position.x
    rendererData.mesh.soundVizReflection.position.y = @SURFACE_Y - rendererData.sound.modification.position.y
    rendererData.mesh.soundVizReflection.rotation.x = - Math.PI
    # FIXME: remove if nessesary
    # @scene.add( rendererData.mesh.soundVizReflection )

    return

  _initVideoRenderer: (rendererData) =>

    rendererData.image = document.createElement( 'canvas' )
    rendererData.image.width = rendererData.streamSize.width
    rendererData.image.height = rendererData.streamSize.height

    rendererData.imageContext = rendererData.image.getContext( '2d' )
    rendererData.imageContext.fillStyle = '#000000'
    rendererData.imageContext.fillRect( 0, 0, rendererData.streamSize.width, rendererData.streamSize.height )

    rendererData.texture = new THREE.Texture( rendererData.image )
    rendererData.texture.minFilter = THREE.LinearFilter

    material = new THREE.MeshBasicMaterial( { map: rendererData.texture, overdraw: 0.5 } )

    materialReflection = new THREE.ShaderMaterial({
      uniforms: {
        'map': { value: rendererData.texture }
      }
      vertexShader: @reflectionShader.vert
      fragmentShader: @reflectionShader.frag
      transparent: true
    } )

    #

    plane = new THREE.PlaneGeometry( 320, 240, 4, 4 )

    rendererData.mesh.original = new THREE.Mesh( plane, material )
    rendererData.mesh.original.position.x = rendererData.modification.position.x
    rendererData.mesh.original.rotation.y = rendererData.modification.rotation.y
    @scene.add( rendererData.mesh.original )

    rendererData.mesh.reflection = new THREE.Mesh( plane, materialReflection )
    rendererData.mesh.reflection.position.x = rendererData.modification.position.x
    rendererData.mesh.reflection.position.y = rendererData.modification.position.y
    rendererData.mesh.reflection.rotation.y = rendererData.modification.rotation.y
    @scene.add( rendererData.mesh.reflection )

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

    material = new THREE.SpriteMaterial({
      color: 0x0808080,
    } )

    for ix in [0...amountx]
      for iy in [0...amounty]
        particle = new THREE.Sprite( material )
        particle.position.x = ix * separation - ( ( amountx * separation ) / 2 )
        particle.position.y = - 120
        particle.position.z = iy * separation - ( ( amounty * separation ) / 2 )
        particle.scale.x = particle.scale.y = 2
        @scene.add( particle )

    @renderer = new THREE.WebGLRenderer( { antialias: true } )

    @renderer.setClearColor( 0xf0f0f0 )
    @renderer.setPixelRatio( window.devicePixelRatio )
    @renderer.setSize( @element.offsetWidth, @element.offsetHeight )
    @container.appendChild( @renderer.domElement )

    if DEBUG == 'true'
      @stats = new Stats()
      @container.appendChild( @stats.dom )

    document.addEventListener( 'mousemove', @_onDocumentMouseMove, false )
    window.addEventListener( 'resize', @_onWindowResize, false )

    @_initSoundVisualizator(@remoteRendererData)
    @_initSoundVisualizator(@localRendererData)

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

  _updateLocalMode: () ->
    if @localRendererData.streamMode.mode.video == 'none'
      if @localRendererData.mesh.original and @localRendererData.mesh.reflection
        @scene.remove(@localRendererData.mesh.original)
        @scene.remove(@localRendererData.mesh.reflection)
      if @localRendererData.mesh.soundViz and @localRendererData.mesh.soundVizReflection
        @scene.add(@localRendererData.mesh.soundViz)
        @scene.add(@localRendererData.mesh.soundVizReflection)
    else if @localRendererData.streamMode.mode.video == '2d'
      if @localRendererData.mesh.original and @localRendererData.mesh.reflection
        @scene.add(@localRendererData.mesh.original)
        @scene.add(@localRendererData.mesh.reflection)
      if @localRendererData.mesh.soundViz and @localRendererData.mesh.soundVizReflection
        @scene.remove(@localRendererData.mesh.soundViz)
        @scene.remove(@localRendererData.mesh.soundVizReflection)

    return

  _animateLocalStream: () ->
    if !!@localRendererData.streamMode
      if @localRendererData.streamMode.mode.video == '2d'

        unless @localStreaming
          localVideoSize = @_getLocalVideoSize()
          unless localVideoSize.width == 0 or localVideoSize.height == 0
            @localRendererData.streamSize.width = localVideoSize.width
            @localRendererData.streamSize.height = localVideoSize.height
            # consider the strem to be started
            @localStreaming = true
            @_initVideoRenderer(@localRendererData)
        else
          if ( @video.readyState == @video.HAVE_ENOUGH_DATA )
            @localRendererData.imageContext.drawImage( @video, 0, 0 )

            if ( @localRendererData.texture )
              @localRendererData.texture.needsUpdate = true

      if @localRendererData.streamMode.mode.video == 'none'
        # NOTE: ICOSAHEDRON
        if (@localRendererData.mesh.original and @localRendererData.mesh.soundVizReflection)
          @localRendererData.mesh.soundViz.rotation.x += 0.005
          @localRendererData.mesh.soundViz.rotation.y += 0.005
          @localRendererData.mesh.soundVizReflection.rotation.x -= 0.005
          @localRendererData.mesh.soundVizReflection.rotation.y -= 0.005

    return

  _updateRemoteMode: () ->
    if @remoteRendererData.streamMode.mode.video == 'none'
      if @remoteRendererData.mesh.original and @remoteRendererData.mesh.reflection
        @scene.remove(@remoteRendererData.mesh.original)
        @scene.remove(@remoteRendererData.mesh.reflection)
      if @remoteRendererData.mesh.soundViz and @remoteRendererData.mesh.soundVizReflection
        @scene.add(@remoteRendererData.mesh.soundViz)
        @scene.add(@remoteRendererData.mesh.soundVizReflection)
    else if @remoteRendererData.streamMode.mode.video == '2d'
      if @remoteRendererData.mesh.original and @remoteRendererData.mesh.reflection
        @scene.add(@remoteRendererData.mesh.original)
        @scene.add(@remoteRendererData.mesh.reflection)
      if @remoteRendererData.mesh.soundViz and @remoteRendererData.mesh.soundVizReflection
        @scene.remove(@remoteRendererData.mesh.soundViz)
        @scene.remove(@remoteRendererData.mesh.soundVizReflection)

    return

  _animateRemoteStream: () ->
    if !!@remoteRendererData.streamMode
      if @remoteRendererData.streamMode.mode.video == '2d'

        unless @remoteStreaming
          remoteVideoSize = @_getRemoteVideoSize()
          unless remoteVideoSize.width == 0 or remoteVideoSize.height == 0
            @remoteRendererData.streamSize.width = remoteVideoSize.width
            @remoteRendererData.streamSize.height = remoteVideoSize.height
            # consider the strem to be started
            @remoteStreaming = true
            @_initVideoRenderer(@remoteRendererData)
        else
          if ( @remoteVideo.readyState == @remoteVideo.HAVE_ENOUGH_DATA )
            @remoteRendererData.imageContext.drawImage( @remoteVideo, 0, 0 )

            if ( @remoteRendererData.texture )
              @remoteRendererData.texture.needsUpdate = true

      if @remoteRendererData.streamMode.mode.video == 'none'
        # NOTE: ICOSAHEDRON
        if (@remoteRendererData.mesh.original and @remoteRendererData.mesh.soundVizReflection)
          @remoteRendererData.mesh.soundViz.rotation.x += 0.005
          @remoteRendererData.mesh.soundViz.rotation.y += 0.005
          @remoteRendererData.mesh.soundVizReflection.rotation.x -= 0.005
          @remoteRendererData.mesh.soundVizReflection.rotation.y -= 0.005

    return

  animate: () ->
    @reqAnimFrame = requestAnimationFrame =>
      @animate()

    @camera.position.x += ( @mouseX - @camera.position.x ) * 0.05
    @camera.position.y += ( - @mouseY - @camera.position.y ) * 0.05
    @camera.lookAt( @scene.position )

    # FIXME: move analyze outside not to do it twice if  both are without video
    @spectrum = @fft.analyze()
    if @visualisatorMaterial
      @visualisatorMaterial.uniforms.spectrum.value = @spectrum
    if @visualisatorReflectionMaterial
      @visualisatorReflectionMaterial.uniforms.spectrum.value = @spectrum

    @_animateLocalStream()
    @_animateRemoteStream()


    @renderer.render( @scene, @camera )

    if DEBUG == 'true'
      @stats.update()

    return

module.exports = AlVideoStreamController
