
class AlHologramRenderer

  HOLOGRAM_W: 640 / 3
  HOLOGRAM_H: 480 / 3

  hologramShaders: {
    frag: require('raw!./shaders/hologramRenderer.frag')
    vert: require('raw!./shaders/hologramRenderer.vert')
    fragReflection: require('raw!./shaders/hologramRendererReflection.frag')
    vertReflection: require('raw!./shaders/hologramRendererReflection.vert')
  }

  constructor: (@rendererData, @scene) ->
    @_init()
    return

  # generate points for rendering field (can be used for point cloud)
  _getArrayOfPoints: ->
    points = []
    width = @HOLOGRAM_W
    height = @HOLOGRAM_H
    yAmount = 480 / 3
    xAmount = 640 / 3
    COORD_MULTIPLIER = 1
    for y in [0...height] by height / yAmount
      row = []
      for x in [0...width] by width / xAmount
        row.push([(x - width / 2) * COORD_MULTIPLIER , (y - height / 2) * COORD_MULTIPLIER, 0])
      points.push(row)
    return points

  # translate points coordinates to LinesSegments acceptable format
  _getLineSegments: (points) ->
    lineSegmentsPoints = []
    vUv = []
    previousPoint = null
    for i in [0...points.length]
      for y in [0...points[i].length]
        if y > 1
          vUv.push((y - 1) / points[i].length)
          vUv.push(i / points.length)
          lineSegmentsPoints.push(points[i][y - 1][0])
          lineSegmentsPoints.push(points[i][y - 1][1])
          lineSegmentsPoints.push(points[i][y - 1][2])

        vUv.push(y / points[i].length)
        vUv.push(i / points.length)
        lineSegmentsPoints.push(points[i][y][0])
        lineSegmentsPoints.push(points[i][y][1])
        lineSegmentsPoints.push(points[i][y][2])

    return {
      lineSegmentsPoints: lineSegmentsPoints,
      vUv: vUv
    }

  _init: () =>
    @rendererData.hologram = {}

    geometry = new THREE.BufferGeometry()
    geometryReflection = new THREE.BufferGeometry()

    lineSegmentsDt = @_getLineSegments(@_getArrayOfPoints())
    lineSegmentsReflectionDt = @_getLineSegments(@_getArrayOfPoints())

    vertices = new Float32Array(lineSegmentsDt.lineSegmentsPoints)
    vUv = new Float32Array(lineSegmentsDt.vUv)

    geometry.addAttribute( 'position', new THREE.BufferAttribute( vertices, 3 ) )
    geometry.addAttribute( 'vUv', new THREE.BufferAttribute( vUv, 2 ) )

    @rendererData.hologram.hologramMaterial = new THREE.ShaderMaterial({
      uniforms:
        textureMap: {type: 't', value: @rendererData.texture}
        wAmount: {type: 'f', value: @HOLOGRAM_W}
        hAmount: {type: 'f', value: @HOLOGRAM_H}
      vertexShader: @hologramShaders.vert
      fragmentShader: @hologramShaders.frag
      side: THREE.DoubleSide
      transparent: true
    } )
    @rendererData.hologram.mesh = new THREE.LineSegments( geometry, @rendererData.hologram.hologramMaterial )

    @rendererData.hologram.hologramReflectionMaterial = new THREE.ShaderMaterial({
      uniforms:
        textureMap: {type: 't', value: @rendererData.texture}
        wAmount: {type: 'f', value: @HOLOGRAM_W}
        hAmount: {type: 'f', value: @HOLOGRAM_H}
      vertexShader: @hologramShaders.vertReflection
      fragmentShader: @hologramShaders.fragReflection
      side: THREE.DoubleSide
      transparent: true
    } )
    @rendererData.hologram.reflectionMesh = new THREE.LineSegments( geometry, @rendererData.hologram.hologramReflectionMaterial)

    return

  updateVisibility: (mode) =>
    if mode == AL_VIDEO_CONST.DEPTH_VIDEO
      unless @scene.getObjectById(@rendererData.hologram.mesh.id)
        @scene.add(@rendererData.hologram.mesh)
      unless @scene.getObjectById(@rendererData.hologram.reflectionMesh.id)
        @scene.add(@rendererData.hologram.reflectionMesh)
    else
      if @scene.getObjectById(@rendererData.hologram.mesh.id)
        @scene.remove(@rendererData.hologram.mesh)
      if @scene.getObjectById(@rendererData.hologram.reflectionMesh.id)
        @scene.remove(@rendererData.hologram.reflectionMesh)
    return

module.exports = AlHologramRenderer
