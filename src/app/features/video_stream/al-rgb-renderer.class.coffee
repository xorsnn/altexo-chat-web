

class AlRgbRenderer

  reflectionShader: {
    frag: require('raw!../../../shaders/reflection.frag')
    vert: require('raw!../../../shaders/reflection.vert')
  }

  constructor: (@avatar) ->
    console.log "al rgb renderer"
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

    # if initHologram
    #
    #   @_initHologram(@avatar.rendererData)
    # console.log @avatar.rendererData.texture

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
