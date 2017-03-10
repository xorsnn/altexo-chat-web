THREE = require('three')

class AlHologramRenderer

  HOLOGRAM_TYPE: 'POINT_CLOUD' # 'LINES'

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
        row.push([
          (x - width / 2) * COORD_MULTIPLIER,
          (y - height / 2) * COORD_MULTIPLIER,
          0
        ])
      points.push(row)
    return points

  _getPointCloud: (points) ->
    lineSegmentsPoints = []
    vUv = []
    previousPoint = null
    for i in [0...points.length]
      for y in [0...points[i].length]
        vUv.push(y / points[i].length)
        vUv.push(i / points.length)
        lineSegmentsPoints.push(points[i][y][0])
        lineSegmentsPoints.push(points[i][y][1])
        lineSegmentsPoints.push(points[i][y][2])
    return {
    lineSegmentsPoints: lineSegmentsPoints,
    vUv: vUv
    }

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

    if @HOLOGRAM_TYPE == 'LINES'
      lineSegmentsDt = @_getLineSegments(@_getArrayOfPoints())
      lineSegmentsReflectionDt = @_getLineSegments(@_getArrayOfPoints())
    else
      lineSegmentsDt = @_getPointCloud(@_getArrayOfPoints())
      lineSegmentsReflectionDt = @_getPointCloud(@_getArrayOfPoints())

    vertices = new Float32Array(lineSegmentsDt.lineSegmentsPoints)
    vUv = new Float32Array(lineSegmentsDt.vUv)

    geometry.addAttribute( 'position', new THREE.BufferAttribute( vertices, 3 ) )
    geometry.addAttribute( 'vUv', new THREE.BufferAttribute( vUv, 2 ) )


    @rendererData.hologram.hologramMaterial = new THREE.ShaderMaterial({
      uniforms:
        textureMap: {type: 't', value: @rendererData.texture}
        wAmount: {type: 'f', value: @HOLOGRAM_W}
        hAmount: {type: 'f', value: @HOLOGRAM_H}
        modificationPosX: {type: 'f', value: @rendererData.modification.position.x}
        # modificationPosY: {type: 'f', value: @rendererData.modification.position.y}
        # modificationPosZ: {type: 'f', value: @rendererData.modification.position.z}
        # modificationRotationX: {type: 'f', value: @rendererData.modification.rotation.x}
        modificationRotationY: {type: 'f', value: @rendererData.modification.rotation.y}
        # modificationRotationZ: {type: 'f', value: @rendererData.modification.rotation.z}
      vertexShader: @hologramShaders.vert
      fragmentShader: @hologramShaders.frag
      side: THREE.DoubleSide
      transparent: true
    } )


    if @HOLOGRAM_TYPE == 'LINES'
      @rendererData.hologram.mesh = \
        new THREE.LineSegments( geometry, @rendererData.hologram.hologramMaterial )
    else
      @rendererData.hologram.mesh = \
        new THREE.PointCloud( geometry, @rendererData.hologram.hologramMaterial )

    @rendererData.hologram.hologramReflectionMaterial = new THREE.ShaderMaterial({
      uniforms:
        textureMap: {type: 't', value: @rendererData.texture}
        wAmount: {type: 'f', value: @HOLOGRAM_W}
        hAmount: {type: 'f', value: @HOLOGRAM_H}
        modificationPosX: {type: 'f', value: @rendererData.modification.position.x}
        # modificationPosY: {type: 'f', value: @rendererData.modification.position.y}
        # modificationPosZ: {type: 'f', value: @rendererData.modification.position.z}
        # modificationRotationX: {type: 'f', value: @rendererData.modification.rotation.x}
        modificationRotationY: {type: 'f', value: @rendererData.modification.rotation.y}
        # modificationRotationZ: {type: 'f', value: @rendererData.modification.rotation.z}
      vertexShader: @hologramShaders.vertReflection
      fragmentShader: @hologramShaders.fragReflection
      side: THREE.DoubleSide
      transparent: true
    } )

    if @HOLOGRAM_TYPE == 'LINES'
      @rendererData.hologram.reflectionMesh = \
        new THREE.LineSegments( geometry, @rendererData.hologram.hologramReflectionMaterial)
    else
      @rendererData.hologram.reflectionMesh = \
        new THREE.PointCloud( geometry, @rendererData.hologram.hologramReflectionMaterial )

    return

  bind: ->
    unless @scene.getObjectById(@rendererData.hologram.mesh.id)
      @scene.add(@rendererData.hologram.mesh)
    unless @scene.getObjectById(@rendererData.hologram.reflectionMesh.id)
      @scene.add(@rendererData.hologram.reflectionMesh)

  unbind: ->
    if @scene.getObjectById(@rendererData.hologram.mesh.id)
      @scene.remove(@rendererData.hologram.mesh)
    if @scene.getObjectById(@rendererData.hologram.reflectionMesh.id)
      @scene.remove(@rendererData.hologram.reflectionMesh)


module.exports = AlHologramRenderer
