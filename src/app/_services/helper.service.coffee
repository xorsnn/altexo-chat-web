# require('../_constants/clean_webgl/al-flow.const.coffee')

angular.module('AltexoApp')
.factory 'Helper',
($timeout, $window, $http, $q, FLOW) ->
  index = 0.1
  randomPointInSphere: () ->
    # lambda = Math.random()
    # u = Math.random() * 2.0 - 1.0
    # phi = Math.random() * 2.0 * Math.PI
    # index += 0.1
    # index = 0.000001
    index = 0
    lambda = (1 + index)
    u = (1 + index) * 2.0 - 1.0
    phi = (1 + index) * 2.0 * Math.PI

    # res = [
    #     Math.pow(lambda, 1/3) * Math.sqrt(1.0 - u * u) * Math.cos(phi)
    #     Math.pow(lambda, 1/3) * Math.sqrt(1.0 - u * u) * Math.sin(phi)
    #     Math.pow(lambda, 1/3) * u
    # ]
    res = [
      1,2,0
    ]
    # console.log res
    # return [
    #     Math.pow(lambda, 1/3) * Math.sqrt(1.0 - u * u) * Math.cos(phi)
    #     Math.pow(lambda, 1/3) * Math.sqrt(1.0 - u * u) * Math.sin(phi)
    #     Math.pow(lambda, 1/3) * u
    # ]
    return res

  buildTexture: (gl, unit, format, type, width, height, data, wrapS, wrapT, minFilter, magFilter) ->
    texture = gl.createTexture()
    gl.activeTexture(gl.TEXTURE0 + unit)
    gl.bindTexture(gl.TEXTURE_2D, texture)
    gl.texImage2D(gl.TEXTURE_2D, 0, format, width, height, 0, format, type, data)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, wrapS)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, wrapT)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, minFilter)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, magFilter)
    return texture

  makeIdentityMatrix: (matrix) ->
    matrix[0] = 1.0
    matrix[1] = 0.0
    matrix[2] = 0.0
    matrix[3] = 0.0
    matrix[4] = 0.0
    matrix[5] = 1.0
    matrix[6] = 0.0
    matrix[7] = 0.0
    matrix[8] = 0.0
    matrix[9] = 0.0
    matrix[10] = 1.0
    matrix[11] = 0.0
    matrix[12] = 0.0
    matrix[13] = 0.0
    matrix[14] = 0.0
    matrix[15] = 1.0
    return matrix

  makeXRotationMatrix: (matrix, angle) ->
    matrix[0] = 1.0
    matrix[1] = 0.0
    matrix[2] = 0.0
    matrix[3] = 0.0
    matrix[4] = 0.0
    matrix[5] = Math.cos(angle)
    matrix[6] = Math.sin(angle)
    matrix[7] = 0.0
    matrix[8] = 0.0
    matrix[9] = -Math.sin(angle)
    matrix[10] = Math.cos(angle)
    matrix[11] = 0.0
    matrix[12] = 0.0
    matrix[13] = 0.0
    matrix[14] = 0.0
    matrix[15] = 1.0
    return matrix

  makeYRotationMatrix: (matrix, angle) ->
    matrix[0] = Math.cos(angle)
    matrix[1] = 0.0
    matrix[2] = -Math.sin(angle)
    matrix[3] = 0.0
    matrix[4] = 0.0
    matrix[5] = 1.0
    matrix[6] = 0.0
    matrix[7] = 0.0
    matrix[8] = Math.sin(angle)
    matrix[9] = 0.0
    matrix[10] = Math.cos(angle)
    matrix[11] = 0.0
    matrix[12] = 0.0
    matrix[13] = 0.0
    matrix[14] = 0.0
    matrix[15] = 1.0
    return matrix

  premultiplyMatrix: (out, matrixA, matrixB) -> #//out = matrixB * matrixA
    [b0, b4, b8, b12] = [matrixB[0], matrixB[4], matrixB[8], matrixB[12]]
    [b1, b5, b9, b13] = [matrixB[1], matrixB[5], matrixB[9], matrixB[13]]
    [b2, b6, b10, b14] = [matrixB[2], matrixB[6], matrixB[10], matrixB[14]]
    [b3, b7, b11, b15] = [matrixB[3], matrixB[7], matrixB[11], matrixB[15]]

    [aX, aY, aZ, aW] = [matrixA[0], matrixA[1], matrixA[2], matrixA[3]]

    out[0] = b0 * aX + b4 * aY + b8 * aZ + b12 * aW
    out[1] = b1 * aX + b5 * aY + b9 * aZ + b13 * aW
    out[2] = b2 * aX + b6 * aY + b10 * aZ + b14 * aW
    out[3] = b3 * aX + b7 * aY + b11 * aZ + b15 * aW

    aX = matrixA[4]
    aY = matrixA[5]
    aZ = matrixA[6]
    aW = matrixA[7]

    out[4] = b0 * aX + b4 * aY + b8 * aZ + b12 * aW
    out[5] = b1 * aX + b5 * aY + b9 * aZ + b13 * aW
    out[6] = b2 * aX + b6 * aY + b10 * aZ + b14 * aW
    out[7] = b3 * aX + b7 * aY + b11 * aZ + b15 * aW

    aX = matrixA[8]
    aY = matrixA[9]
    aZ = matrixA[10]
    aW = matrixA[11]

    out[8] = b0 * aX + b4 * aY + b8 * aZ + b12 * aW
    out[9] = b1 * aX + b5 * aY + b9 * aZ + b13 * aW
    out[10] = b2 * aX + b6 * aY + b10 * aZ + b14 * aW
    out[11] = b3 * aX + b7 * aY + b11 * aZ + b15 * aW

    aX = matrixA[12]
    aY = matrixA[13]
    aZ = matrixA[14]
    aW = matrixA[15]

    out[12] = b0 * aX + b4 * aY + b8 * aZ + b12 * aW
    out[13] = b1 * aX + b5 * aY + b9 * aZ + b13 * aW
    out[14] = b2 * aX + b6 * aY + b10 * aZ + b14 * aW
    out[15] = b3 * aX + b7 * aY + b11 * aZ + b15 * aW

    return out

  makePerspectiveMatrix: (matrix, fov, aspect, near, far) ->
    f = Math.tan(0.5 * (Math.PI - fov))
    range = near - far

    matrix[0] = f / aspect
    matrix[1] = 0
    matrix[2] = 0
    matrix[3] = 0
    matrix[4] = 0
    matrix[5] = f
    matrix[6] = 0
    matrix[7] = 0
    matrix[8] = 0
    matrix[9] = 0
    matrix[10] = far / range
    matrix[11] = -1
    matrix[12] = 0
    matrix[13] = 0
    matrix[14] = (near * far) / range
    matrix[15] = 0.0

    return matrix

  makeLookAtMatrix: (matrix, eye, target, up) -> #//up is assumed to be normalized
    forwardX = eye[0] - target[0]
    forwardY = eye[1] - target[1]
    forwardZ = eye[2] - target[2]

    forwardMagnitude = Math.sqrt(forwardX * forwardX + forwardY * forwardY + forwardZ * forwardZ)

    forwardX /= forwardMagnitude
    forwardY /= forwardMagnitude
    forwardZ /= forwardMagnitude

    rightX = up[2] * forwardY - up[1] * forwardZ
    rightY = up[0] * forwardZ - up[2] * forwardX
    rightZ = up[1] * forwardX - up[0] * forwardY

    rightMagnitude = Math.sqrt(rightX * rightX + rightY * rightY + rightZ * rightZ)
    rightX /= rightMagnitude
    rightY /= rightMagnitude
    rightZ /= rightMagnitude

    newUpX = forwardY * rightZ - forwardZ * rightY
    newUpY = forwardZ * rightX - forwardX * rightZ
    newUpZ = forwardX * rightY - forwardY * rightX

    newUpMagnitude = Math.sqrt(newUpX * newUpX + newUpY * newUpY + newUpZ * newUpZ)
    newUpX /= newUpMagnitude
    newUpY /= newUpMagnitude
    newUpZ /= newUpMagnitude

    matrix[0] = rightX
    matrix[1] = newUpX
    matrix[2] = forwardX
    matrix[3] = 0
    matrix[4] = rightY
    matrix[5] = newUpY
    matrix[6] = forwardY
    matrix[7] = 0
    matrix[8] = rightZ
    matrix[9] = newUpZ
    matrix[10] = forwardZ
    matrix[11] = 0
    matrix[12] = -(rightX * eye[0] + rightY * eye[1] + rightZ * eye[2])
    matrix[13] = -(newUpX * eye[0] + newUpY * eye[1] + newUpZ * eye[2])
    matrix[14] = -(forwardX * eye[0] + forwardY * eye[1] + forwardZ * eye[2])
    matrix[15] = 1
    return

  makeOrthographicMatrix: (matrix, left, right, bottom, top, near, far) ->
    matrix[0] = 2 / (right - left)
    matrix[1] = 0
    matrix[2] = 0
    matrix[3] = 0
    matrix[4] = 0
    matrix[5] = 2 / (top - bottom)
    matrix[6] = 0
    matrix[7] = 0
    matrix[8] = 0
    matrix[9] = 0
    matrix[10] = -2 / (far - near)
    matrix[11] = 0
    matrix[12] = -(right + left) / (right - left)
    matrix[13] = -(top + bottom) / (top - bottom)
    matrix[14] = -(far + near) / (far - near)
    matrix[15] = 1

    return matrix

  log2: (x) ->
    return Math.log(x) / Math.log(2)

  buildFramebuffer: (gl, attachment) ->
    framebuffer = gl.createFramebuffer()
    gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer)
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, attachment, 0)
    return framebuffer

  buildProgramWrapper: (gl, vertexShader, fragmentShader, attributeLocations) ->
    programWrapper = {}

    program = gl.createProgram()
    gl.attachShader(program, vertexShader)
    gl.attachShader(program, fragmentShader)

    # TODO take a look for coffee
    for attributeName in attributeLocations
      gl.bindAttribLocation(program, attributeLocations[attributeName], attributeName)

    gl.linkProgram(program)
    uniformLocations = {}
    numberOfUniforms = gl.getProgramParameter(program, gl.ACTIVE_UNIFORMS)
    for i in [0...numberOfUniforms]
      activeUniform = gl.getActiveUniform(program, i)
      # console.log '=================='
      # console.log program
      # console.log activeUniform.name
      uniformLocation = gl.getUniformLocation(program, activeUniform.name)
      uniformLocations[activeUniform.name] = uniformLocation

    programWrapper.program = program
    programWrapper.uniformLocations = uniformLocations

    return programWrapper

  buildShader: (gl, type, source) ->
    shader = gl.createShader(type)
    gl.shaderSource(shader, source)
    gl.compileShader(shader)
    # //console.log(gl.getShaderInfoLog(shader));
    return shader

  dotVectors: (a, b) ->
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]

  normalizeVector: (out, v) ->
    inverseMagnitude = 1.0 / Math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2])
    out[0] = v[0] * inverseMagnitude
    out[1] = v[1] * inverseMagnitude
    out[2] = v[2] * inverseMagnitude
    return

  hsvToRGB: (h, s, v) ->
    h = h % 1

    c = v * s

    hDash = h * 6

    x = c * (1 - Math.abs(hDash % 2 - 1))

    mod = Math.floor(hDash)

    r = [c, x, 0, 0, x, c][mod]
    g = [x, c, c, x, 0, 0][mod]
    b = [0, 0, x, c, c, x][mod]

    m = v - c

    r += m
    g += m
    b += m

    return [r, g, b]

  getMousePosition: (event, element) ->
    boundingRect = element.getBoundingClientRect()
    return {
      x: event.clientX - boundingRect.left
      y: event.clientY - boundingRect.top
    }

  hasWebGLSupportWithExtensions: (extensions) ->
    canvas = document.createElement('canvas')
    gl = null
    try
      gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl')
    catch e
      return false

    if (gl == null)
      return false

    for i in [0...extensions.length]
      if (gl.getExtension(extensions[i]) == null)
        return false

    return true
