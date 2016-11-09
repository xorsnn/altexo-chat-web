Detector = require('../../../../node_modules/three/examples/js/Detector.js')

require('../../../../node_modules/three/examples/js/renderers/Projector.js')

if DEBUG == 'true'
  Stats = require('../../../../node_modules/three/examples/js/libs/stats.min.js')

global.p5 = require('p5')
sylvester = require('sylvester')
for attrname in Object.keys(sylvester)
  global[attrname] = sylvester[attrname]

require('../../../../node_modules/p5/lib/addons/p5.dom.js')
require('../../../../node_modules/p5/lib/addons/p5.sound.js')

AlAvatar = require('./al-avatar.class.coffee')

class AlVideoStreamController
  webglRenderer: Detector.webgl

  AMOUNT: 100

  reqAnimFrame: null
  container: null
  stats: null
  camera: null
  scene: null
  renderer: null

  localAvatar: null
  remoteAvatar: null

  ### @ngInject ###
  constructor: ($scope, $element, $timeout, $rootScope, AL_VIDEO_VIS) ->
    @scope = $scope # todo eliminate this

    @AL_VIDEO_VIS = AL_VIDEO_VIS

    @element = $element[0]

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
          video: @AL_VIDEO_VIS.RGB_VIDEO,
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
            y: @AL_VIDEO_VIS.ICOSAHEDRON_RADIUS + (@AL_VIDEO_VIS.ICOSAHEDRON_RADIUS * @AL_VIDEO_VIS.SURFACE_DISTANCE_KOEFFICIENT) # surface coordinate - 120
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
      hologram: null
      streamMode: {
        mode: {
          video: @AL_VIDEO_VIS.RGB_VIDEO,
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
            x: - 320
            y: @AL_VIDEO_VIS.ICOSAHEDRON_RADIUS + (@AL_VIDEO_VIS.ICOSAHEDRON_RADIUS * @AL_VIDEO_VIS.SURFACE_DISTANCE_KOEFFICIENT) # surface coordinate - 120
            z: 0
          }
        }
      }
    }

    @mouseX = 0
    @mouseY = 0

    @windowHalfX = window.innerWidth / 2
    @windowHalfY = window.innerHeight / 2

    mic = new p5.AudioIn()
    mic.start()
    @fft = new p5.FFT(0.8, 16)
    @fft.setInput(mic)

    $element.ready () =>
      $timeout () =>
        @_init()
        @_updateMode()
        @animate()
      , 0

    $scope.$on '$destroy', () =>
      cancelAnimationFrame(@reqAnimFrame)
      return

    $rootScope.$on 'al-mode-change', (event, data) =>
      @remoteRendererData.streamMode = if !!data.remote then data.remote else @remoteRendererData.streamMode
      @localRendererData.streamMode = if !!data.local then data.local else @localRendererData.streamMode
      @_updateMode()
      @_updateNicks()
      return

    return

  _updateNicks: =>
    if @localAvatar
      @localAvatar.updateLabel(@scope.$storage.nickname)
    if @remoteAvatar
      if @remoteRendererData.streamMode.name
        @remoteAvatar.updateLabel(@remoteRendererData.streamMode.name)
    return

  _updateMode: ->
    if @remoteRendererData.streamMode
      @_updateRemoteMode()
    if @localRendererData.streamMode
      @_updateLocalMode()
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

    # Load fonts
    # @_initLabels()
    @localAvatar = new AlAvatar(@localRendererData, @scene, document.getElementById( 'localVideo' ))
    @remoteAvatar = new AlAvatar(@remoteRendererData, @scene, document.getElementById( 'remoteVideo' ))
    @_updateNicks()

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

  _updateLocalMode: () ->
    if @localAvatar
      @localAvatar.updateMode()
    return

  _updateRemoteMode: () ->
    if @remoteAvatar
      @remoteAvatar.updateMode()
    return

  animate: () ->
    @reqAnimFrame = requestAnimationFrame =>
      @animate()

    @camera.position.x += ( @mouseX - @camera.position.x ) * 0.05
    @camera.position.y += ( - @mouseY - @camera.position.y ) * 0.05
    @camera.lookAt( @scene.position )

    # FIXME: define if analyze is needed
    @spectrum = @fft.analyze()

    @localAvatar.setSpectrum(@spectrum)
    @remoteAvatar.setSpectrum(@spectrum)

    @localAvatar.animate()
    @remoteAvatar.animate()

    @renderer.render( @scene, @camera )

    if DEBUG == 'true'
      @stats.update()

    return

module.exports = AlVideoStreamController
