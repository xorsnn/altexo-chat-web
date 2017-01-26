AlAvatar = require './video_stream/al-avatar.class.coffee'


angular.module('AltexoApp')

.directive 'altexoRoomRenderer', ($window, RendererHelper) -> {
  restrict: 'A'
  link: ($scope, $element, { altexoRoomRenderer }) ->
    chatRoom = $scope.$eval(altexoRoomRenderer)

    element = $element.get(0)

    windowHalfX = $window.innerWidth / 2
    windowHalfY = $window.innerHeight / 2

    mouseX = 0
    mouseY = 0

    mic = new p5.AudioIn()
    mic.start()
    fft = new p5.FFT(0.8, 16)
    fft.setInput(mic)

    renderer = new THREE.WebGLRenderer({ antialias: true })
    renderer.setClearColor(0xf0f0f0)
    renderer.setPixelRatio($window.devicePixelRatio)
    renderer.setSize(element.offsetWidth, element.offsetHeight)

    camera = new THREE.PerspectiveCamera(45, element.offsetWidth / element.offsetHeight, 1, 10000)
    camera.position.z = 1000

    scene = new THREE.Scene()

    raycaster = new THREE.Raycaster()
    mouse = new THREE.Vector2()

    ##
    # TODO: refactor: use list of avatar renderers instead of hardcoded couple

    localRendererData = RendererHelper.buildRendererData(false)
    localAvatar = new AlAvatar(localRendererData, scene, document.getElementById( 'localVideo' ), camera)

    remoteRendererData = RendererHelper.buildRendererData(true)
    remoteAvatar = new AlAvatar(remoteRendererData, scene, document.getElementById( 'remoteVideo' ), camera)

    getAvatar = (contact) ->
      if contact.id == chatRoom.creator
        return localAvatar
      return remoteAvatar

    avatars = [localAvatar, remoteAvatar]

    chatRoom.contacts.forEach (contact) ->
      getAvatar(contact).updateLabel(contact.name)
      getAvatar(contact).updateMode(contact.mode)

    ##  /refactor

    RendererHelper.addParticleGrid(scene)

    render = ->
      camera.position.x += ( mouseX - camera.position.x ) * 0.05
      camera.position.y += ( - mouseY - camera.position.y ) * 0.05
      camera.lookAt( scene.position )

      # FIXME: define if analyze is needed
      spectrum = fft.analyze()

      for avatar in avatars
        avatar.setSpectrum(spectrum)

      for avatar in avatars
        avatar.animate()

      renderer.render(scene, camera)

    $element.ready ->
      element.appendChild(renderer.domElement)

      animate = $scope.$runAnimation(render)
      animate()  # start animation

    $scope.$listenWindow 'resize', (ev) ->
      windowHalfX = element.offsetWidth / 2
      windowHalfY = element.offsetHeight / 2

      camera.aspect = element.offsetWidth / element.offsetHeight
      camera.updateProjectionMatrix()

      renderer.setSize(element.offsetWidth, element.offsetHeight)

    $scope.$listenDocument 'mousemove', (ev) ->
      mouseX = ev.clientX - windowHalfX
      mouseY = (ev.clientY - windowHalfY) * 0.2

    $scope.$listenDocument 'mousedown', (ev) ->
      mouse.x = ( ev.clientX / $window.innerWidth ) * 2 - 1
      mouse.y = -( ( ev.clientY / $window.innerHeight ) * 2 - 1 )
      raycaster.setFromCamera(mouse, camera)
      intersects = raycaster.intersectObjects(scene.children)
      if intersects.length > 0
        for avatar in avatars
          avatar.objectsClicked(intersects)
      return

    $scope.$listenObject chatRoom, 'add', (contact) ->
      getAvatar(contact).updateLabel(contact.name)
      getAvatar(contact).updateMode(contact.mode)

    # $scope.$listenObject chatRoom, 'remove', (contact) ->
    #   console.log '>> CHAT REMOVE USER', contact

    $scope.$listenObject chatRoom, 'update', (contact) ->
      getAvatar(contact).updateLabel(contact.name)
      getAvatar(contact).updateMode(contact.mode)
}

.service 'RendererHelper', (AL_VIDEO_VIS) -> {
  buildRendererData: (leftSide) -> {
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
        y: Math.PI / 6 * (if leftSide then 1 else -1)
        z: 0
      }
      position: {
        x: 320 * (if leftSide then -1 else 1)
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
          x: 320 * (if leftSide then -1 else 1)
          y: AL_VIDEO_VIS.ICOSAHEDRON_RADIUS + (AL_VIDEO_VIS.ICOSAHEDRON_RADIUS * AL_VIDEO_VIS.SURFACE_DISTANCE_KOEFFICIENT) # surface coordinate - 120
          z: 0
        }
      }
    }
  }

  addParticleGrid: (scene) ->
    separation = 150
    amountx = 10
    amounty = 10

    material = new THREE.SpriteMaterial({
      color: 0x0808080
    })

    for ix in [0...amountx]
      for iy in [0...amounty]
        particle = new THREE.Sprite( material )
        particle.position.x = ix * separation - ( ( amountx * separation ) / 2 )
        particle.position.y = - 120
        particle.position.z = iy * separation - ( ( amounty * separation ) / 2 )
        particle.scale.x = particle.scale.y = 2
        
        scene.add(particle)

    return
}

.run ($rootScope, $window, $document) ->
  $rootScope.$listenObject = (obj, name, handler) ->
    endListener = obj.$on(name, handler)
    this.$on('$destroy', endListener)

  $rootScope.$listenDocument = (name, handler) ->
    this.$on '$destroy', ->
      $document.off(name, handler)
    $document.on(name, handler)

  $rootScope.$listenWindow = (name, handler) ->
    this.$on '$destroy', ->
      $window.removeEventListener(name, handler)
    $window.addEventListener(name, handler, false)

  $rootScope.$runAnimation = (render) ->
    _rafid = null
    this.$on '$destroy', ->
      unless _rafid == null
        cancelAnimationFrame(_rafid)
    animate = ->
      _rafid = requestAnimationFrame(animate)
      render()

  return

.component 'altexoComponentWebRtc', {
  transclude: true
  template: '''
  <video class="local" /> <video class="remote" /> 
  '''
  template: '<p>HEY <h2>huba huba {{:: $ctrl.value }}</h2><div ng-transclude /></p>'
  controller: ->
    console.log '>> COMPONENT IS UP'
    @value = 123
}
