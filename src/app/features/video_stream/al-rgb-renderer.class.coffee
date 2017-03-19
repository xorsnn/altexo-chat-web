THREE = require('three')

REFLECTION_FRAG = require('raw!../../../shaders/reflection.frag')
REFLECTION_VERT = require('raw!../../../shaders/reflection.vert')

module.exports =
  class Renderer

    originalMesh: null
    reflectionMesh: null

    render: (context) ->
      context.updateTexture()
      @

    bind: ({ @scene }) ->
      @scene.add(@originalMesh)
      @scene.add(@reflectionMesh)
      @

    unbind: ->
      safeRemove = (obj) =>
        if @scene.getObjectById(obj.id)
          @scene.remove(obj)
      safeRemove(@originalMesh)
      safeRemove(@reflectionMesh)
      @scene = null
      @

    setTexture: (texture) ->
      @originalMesh = buildOriginalMesh(texture)
      @reflectionMesh = buildReflectionMesh(texture)
      @

    setXPosition: (value) ->
      @originalMesh.position.x = value
      @reflectionMesh.position.x = value
      @

    setYPosition: (value) ->
      @reflectionMesh.position.y = value
      @

    setYRotation: (value) ->
      @originalMesh.rotation.y = value
      @reflectionMesh.rotation.y = value
      @

    isIntersected: (intersects) ->
      for intersect in intersects
        if @originalMesh == intersect.object
          return true
      return false

    # private helpers
    buildReflectionMesh = (texture) ->
      materialReflection = new THREE.ShaderMaterial {
        uniforms: { 'map': { value: texture } }
        vertexShader: REFLECTION_VERT
        fragmentShader: REFLECTION_FRAG
        transparent: true
      }

      # TODO: move width and height to parameters
      plane = new THREE.PlaneGeometry( 320, 240, 4, 4 )

      return new THREE.Mesh( plane, materialReflection )

    buildOriginalMesh = (texture) ->
      material = new THREE.MeshBasicMaterial {
        map: texture
        overdraw: 0.5
      }

      # TODO: move width and height to parameters
      plane = new THREE.PlaneGeometry( 320, 240, 4, 4 )

      return new THREE.Mesh( plane, material )
