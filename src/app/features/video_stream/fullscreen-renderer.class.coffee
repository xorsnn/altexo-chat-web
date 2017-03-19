THREE = require('three')

module.exports =
  class FullscreenRenderer

    originalMesh: null

    render: (context) ->
      context.updateTexture()
      @setRotation(@camera.rotation)
      .setPosition(@camera.position)
      @

    animate: ->
      @setRotation(@camera.rotation)
      .setPosition(@camera.position)
      @

    bind: ({ @scene, @camera }) ->
      @scene.add(@originalMesh)
      @

    unbind: ->
      safeRemove = (obj) =>
        if @scene.getObjectById(obj.id)
          @scene.remove(obj)
      safeRemove(@originalMesh)
      @scene = null
      @camera = null
      @

    setTexture: (texture) ->
      @originalMesh = buildOriginalMesh(texture)
      @

    setRotation: ({ x, y, z }) ->
      @originalMesh.rotation.x = x
      @originalMesh.rotation.y = y
      @originalMesh.rotation.z = z
      @

    setPosition: ({ x, y, z }) ->
      _dest = dest(x, y, z)
      _k = (_dest - 400) / _dest
      @originalMesh.position.x = x * _k
      @originalMesh.position.y = y * _k
      @originalMesh.position.z = z * _k
      @

    isIntersected: (intersects) ->
      for intersect in intersects
        if @originalMesh == intersect.object
          return true
      return false

    # private helpers
    buildOriginalMesh = (texture) ->
      material = new THREE.MeshBasicMaterial {
        map: texture
        overdraw: 0.5
      }

      # TODO: move width and height to parameters
      plane = new THREE.PlaneGeometry( 320, 240, 4, 4 )

      return new THREE.Mesh( plane, material )

    dest = (x, y, z) ->
      Math.sqrt(Math.pow(x, 2) + Math.pow(y, 2) + Math.pow(z, 2))
