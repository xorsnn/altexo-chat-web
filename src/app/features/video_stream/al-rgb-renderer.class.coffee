

class AlRgbRenderer

  reflectionShader: {
    frag: require('raw!../../../shaders/reflection.frag')
    vert: require('raw!../../../shaders/reflection.vert')
  }

  fullscreenMode: false

  constructor: (@avatar, @camera) ->
    @_init()
    return

  _init: () =>

    material = new THREE.MeshBasicMaterial( { map: @avatar.rendererData.texture, overdraw: 0.5 } )

    materialReflection = new THREE.ShaderMaterial({
      uniforms: {
        'map': { value: @avatar.rendererData.texture }
      }
      vertexShader: @reflectionShader.vert
      fragmentShader: @reflectionShader.frag
      transparent: true
    } )

    #

    # TODO: move width and height to parameters
    plane = new THREE.PlaneGeometry( 320, 240, 4, 4 )

    @avatar.rendererData.mesh.original = new THREE.Mesh( plane, material )
    @avatar.rendererData.mesh.original.position.x = @avatar.rendererData.modification.position.x
    @avatar.rendererData.mesh.original.rotation.y = @avatar.rendererData.modification.rotation.y

    @avatar.rendererData.mesh.reflection = new THREE.Mesh( plane, materialReflection )
    @avatar.rendererData.mesh.reflection.position.x = @avatar.rendererData.modification.position.x
    @avatar.rendererData.mesh.reflection.position.y = @avatar.rendererData.modification.position.y
    @avatar.rendererData.mesh.reflection.rotation.y = @avatar.rendererData.modification.rotation.y

    return

  _toDefaultPosition: () =>
    # TODO: implement for reflection also
    @avatar.rendererData.mesh.original.position.x = @avatar.rendererData.modification.position.x
    @avatar.rendererData.mesh.original.position.y = 0
    @avatar.rendererData.mesh.original.position.z = 0
    @avatar.rendererData.mesh.original.rotation.x = 0
    @avatar.rendererData.mesh.original.rotation.y = @avatar.rendererData.modification.rotation.y
    @avatar.rendererData.mesh.original.rotation.z = 0

  toggleFullscreen: () =>
    @fullscreenMode = ! @fullscreenMode
    unless @fullscreenMode
      @_toDefaultPosition()
    return


  animate: () =>
    if @fullscreenMode
      @avatar.rendererData.mesh.original.rotation.x = @camera.rotation.x
      @avatar.rendererData.mesh.original.rotation.y = @camera.rotation.y
      @avatar.rendererData.mesh.original.rotation.z = @camera.rotation.z

      l = Math.sqrt(Math.pow(@camera.position.x, 2) + Math.pow(@camera.position.y, 2) + Math.pow(@camera.position.z, 2))
      l2 = 400
      k = (l - l2) / l

      @avatar.rendererData.mesh.original.position.x = @camera.position.x * k
      @avatar.rendererData.mesh.original.position.y = @camera.position.y * k
      @avatar.rendererData.mesh.original.position.z = @camera.position.z * k
    return

  updateVisibility: (mode) =>
    if mode == AL_VIDEO_CONST.RGB_VIDEO
      unless @avatar.scene.getObjectById(@avatar.rendererData.mesh.original.id)
        @avatar.scene.add(@avatar.rendererData.mesh.original)
      unless @avatar.scene.getObjectById(@avatar.rendererData.mesh.reflection.id)
        @avatar.scene.add(@avatar.rendererData.mesh.reflection)
    else
      if @avatar.scene.getObjectById(@avatar.rendererData.mesh.original.id)
        @avatar.scene.remove(@avatar.rendererData.mesh.original)
      if @avatar.scene.getObjectById(@avatar.rendererData.mesh.reflection.id)
        @avatar.scene.remove(@avatar.rendererData.mesh.reflection)

module.exports = AlRgbRenderer
