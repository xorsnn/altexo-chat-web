

class AlSoundRenderer
  @visualisatorMaterial: null
  @spectrum: null

  constructor: (@rendererData, @scene) ->
    # ANALYZE MIC INPUT
    @spectrum = []
    for i in [0...12]
      @spectrum.push(1)

    @_init()

    return

  _init: () =>
    unless @visualisatorMaterial
      @visualisatorMaterial = new THREE.ShaderMaterial({
        uniforms:
          spectrum: { type: 'fv1', value: @spectrum }
          distanceK: { type: 'f', value: AL_VIDEO_CONST.SURFACE_DISTANCE_KOEFFICIENT}
        vertexShader: require('raw!./shaders/icosahedron.vert')
        fragmentShader: require('raw!./shaders/icosahedron.frag')
        wireframe: true
        side: THREE.DoubleSide
        transparent: true
      } )

    geometry = new THREE.IcosahedronGeometry(AL_VIDEO_CONST.ICOSAHEDRON_RADIUS, 0)

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

    @rendererData.mesh.soundViz = new THREE.Mesh(
      bufferGeometry,
      @visualisatorMaterial
    )

    @rendererData.mesh.soundViz.position.x = @rendererData.sound.modification.position.x
    @rendererData.mesh.soundViz.position.y = AL_VIDEO_CONST.SURFACE_Y + @rendererData.sound.modification.position.y

    unless @visualisatorReflectionMaterial
      @visualisatorReflectionMaterial = new THREE.ShaderMaterial({
        uniforms:
          icosahedronRadius: {type: 'f', value: AL_VIDEO_CONST.ICOSAHEDRON_RADIUS}
          centerY: {type: 'f', value: AL_VIDEO_CONST.SURFACE_Y - @rendererData.sound.modification.position.y}
          spectrum: { type: 'fv1', value: @spectrum }
          distanceK: { type: 'f', value: AL_VIDEO_CONST.SURFACE_DISTANCE_KOEFFICIENT}
        vertexShader: require('raw!./shaders/icosahedron_reflection.vert')
        fragmentShader: require('raw!./shaders/icosahedron_reflection.frag')
        wireframe: true
        side: THREE.DoubleSide
        transparent: true
      } )

    @rendererData.mesh.soundVizReflection = new THREE.Mesh(
      bufferGeometry,
      @visualisatorReflectionMaterial
    )

    @rendererData.mesh.soundVizReflection.position.x = @rendererData.sound.modification.position.x
    @rendererData.mesh.soundVizReflection.position.y = AL_VIDEO_CONST.SURFACE_Y - @rendererData.sound.modification.position.y
    @rendererData.mesh.soundVizReflection.rotation.x = - Math.PI

    return

  updateVisibility: (mode) =>
    if mode == AL_VIDEO_CONST.NO_VIDEO
      @bind()
    else
      @unbind()
    return

  bind: ->
    unless @scene.getObjectById(@rendererData.mesh.soundViz.id)
      @scene.add(@rendererData.mesh.soundViz)
    unless @scene.getObjectById(@rendererData.mesh.soundVizReflection.id)
      @scene.add(@rendererData.mesh.soundVizReflection)

  unbind: ->
    if @scene.getObjectById(@rendererData.mesh.soundViz.id)
      @scene.remove(@rendererData.mesh.soundViz)
    if @scene.getObjectById(@rendererData.mesh.soundVizReflection.id)
      @scene.remove(@rendererData.mesh.soundVizReflection)

  setSpectrum: (spec) =>
    @visualisatorMaterial.uniforms.spectrum.value = spec
    @visualisatorReflectionMaterial.uniforms.spectrum.value = spec
    return

  animate: () =>
    # NOTE: ICOSAHEDRON
    if (@rendererData.mesh.soundViz and @rendererData.mesh.soundVizReflection)
      @rendererData.mesh.soundViz.rotation.x += 0.005
      @rendererData.mesh.soundViz.rotation.y += 0.005
      @rendererData.mesh.soundVizReflection.rotation.x -= 0.005
      @rendererData.mesh.soundVizReflection.rotation.y -= 0.005
    return

module.exports = AlSoundRenderer
