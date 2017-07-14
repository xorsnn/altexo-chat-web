THREE = require('three')
require('three/examples/js/vr/WebVR')

if DEBUG == 'true'
  Stats = require('three/examples/js/libs/stats.min')

p5 = require('p5')
require('p5/lib/addons/p5.dom')
require('p5/lib/addons/p5.sound')

AltexoAvatar = require './video_stream/al-avatar.class.coffee'


angular.module('AltexoApp')

.directive 'altexoRoomRenderer', ($window, RendererHelper, $mdMedia, AlWebVR) -> {
  restrict: 'A'
  link: ($scope, $element, { altexoRoomRenderer }) ->
    chatRoom = $scope.$eval(altexoRoomRenderer)

    webVR = new AlWebVR
    webVR.checkAvailability().catch ( message ) ->
      # TODO: style message container
      document.body.appendChild( webVR.getMessageContainer( message ) )

    element = $element[0]

    windowHalfX = $window.innerWidth / 2
    windowHalfY = $window.innerHeight / 2

    mouseX = 0
    mouseY = 0

    stats = null
    if DEBUG == 'true'
      stats = new Stats()
      angular.element(stats.dom).css({
        top: '50px', right: '16px', left: ''
      })

    mic = new p5.AudioIn()
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

    avatars = new Map()


    shuffle = ->
      if not chatRoom.p2p
        console.debug '>> SHUFFLE', 'kurento case'
        n = 0
        avatars.forEach (avatar) ->
          avatar.setSource {
            place: n
            total: avatars.size
          }
          n = n + 1
      else
        console.debug '>> SHUFFLE', 'p2p case'
        avatars.forEach (avatar) ->
          avatar.setSource { place: 1, total: 1 }
      return

    createAvatar = (contact) ->
      console.debug '>> CREATE AVATAR', contact, '(CURRENTLY:', avatars.size, ')'

      seatNumber = chatRoom.getSeat(contact)
      media = $mdMedia('xs')

      avatar = new AltexoAvatar().setSeat(seatNumber, media).bind {
        video: chatRoom.selectVideoElement(contact)
        scene, camera
      }

      avatars.set(contact.id,
        avatar.setLabel(contact.name)
        .setMode(contact.mode)
        .setFullscreen(chatRoom.isFullscreen(contact)))

      shuffle()

    removeAvatar = (contact) ->
      console.debug '>> REMOVE AVATAR', contact

      avatars.get(contact.id).unbind()
      avatars.delete(contact.id)

      shuffle()

    updateAvatar = (contact) ->
      console.debug '>> UPDATE AVATAR', contact

      avatars.get(contact.id).setLabel(contact.name)
      .setMode(contact.mode)

    startMic = ->
      console.debug '>> START p5.MICROPHONE'
      mic.start()

    # REF: https://github.com/processing/p5.js-sound/commit/1d7816b154ea5ccb728742a67d5f55c0cc6ed62e
    stopMic = ->
      console.debug '>> STOP p5.MICROPHONE'
      mic.stream?.getTracks().forEach (track) -> track.stop()

    toggleMic = (value) ->
      if value then startMic() else stopMic()

    $scope.$on('$destroy', stopMic)

    console.debug '>> INIT RENDERER', chatRoom, chatRoom.contacts.size
    chatRoom.contacts.forEach(createAvatar)

    RendererHelper.addParticleGrid(scene)

    render = ->
      # camera.position.x += ( mouseX - camera.position.x ) * 0.05
      # camera.position.y += ( - mouseY - camera.position.y ) * 0.05
      # camera.lookAt( scene.position )

      if chatRoom.muted.length
        spectrum = fft.analyze()
        chatRoom.muted.forEach (id) ->
          avatars.get(id).setSpectrum(spectrum)

      avatars.forEach (avatar) ->
        avatar.render()

      renderer.render(scene, camera)

    $element.ready ->
      # if DEBUG == 'true'
      #   element.appendChild(RendererHelper.createInfoDiv())

      element.appendChild(renderer.domElement)

      renderer.vr.enabled = true
      console.log "VR enable"
      webVR.getVRDisplay ( display ) ->
        console.log "vr display: "
        console.log display
        renderer.vr.setDevice( display )
        btn = WEBVR.getButton( display, renderer.domElement )
        console.log btn
        document.body.appendChild( btn )


      if DEBUG == 'true'
        animate = $scope.$runAnimation ->
          render()
          stats.update()
        element.appendChild(stats.dom)
      else
        animate = $scope.$runAnimation(render)

      toggleMic(chatRoom.muted.length > 0)
      animate() # start animation

    $scope.$listenObject(chatRoom, 'mute', toggleMic)
    $scope.$listenObject(chatRoom, 'add', createAvatar)
    $scope.$listenObject(chatRoom, 'remove', removeAvatar)
    $scope.$listenObject(chatRoom, 'update', updateAvatar)

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
        avatars.forEach (avatar) ->
          avatar.objectsClicked(intersects)
      return
}

.service 'RendererHelper', -> {
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

  createInfoDiv: ->
    info = document.createElement( 'div' )
    info.style.position = 'absolute'
    info.style.top = '10px'
    info.style.width = '100%'
    info.style.textAlign = 'center'
    info.innerHTML = '<a href="https://altexo.com" target="_blank">Altexo</a> demo'

    return info
}
