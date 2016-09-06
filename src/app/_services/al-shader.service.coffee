angular.module('altexoApp')
.factory 'AlShader',
($http) ->
  class AlShader
    constructor: (@gl, @vsh, @fsh) ->
      @program = null
      vertexShader = @_compileShader(@gl.VERTEX_SHADER, @vsh)
      fragmentShader = @_compileShader(@gl.FRAGMENT_SHADER, @fsh)

      @program = @gl.createProgram()
      if (@program == 0)
        alert("glCreateProgram() failed. GLES20 error: " + @gl.glGetError())

      @gl.attachShader(@program, vertexShader)
      @gl.attachShader(@program, fragmentShader)
      @gl.linkProgram(@program)
      if (!@gl.getProgramParameter(@program, @gl.LINK_STATUS))
        alert("Unable to initialize the shader program: " + @gl.getProgramInfoLog(@program));

      @gl.deleteShader(vertexShader)
      @gl.deleteShader(fragmentShader)
      return

    _compileShader: (shaderType, source) ->
      shader = @gl.createShader(shaderType)
      if shader == 0
        alert "glCreateShader() failed. GLES20 error: " + @gl.glGetError()
      @gl.shaderSource(shader, source)
      @gl.compileShader(shader)

      # See if it compiled successfully
      if (!@gl.getShaderParameter(shader, @gl.COMPILE_STATUS))
        alert("An error occurred compiling the shaders: " + @gl.getShaderInfoLog(shader));
        return null;

      return shader

    getAttribLocation: (label) ->
      if (@program == -1)
        alert("The program has been released")
      location = @gl.getAttribLocation(@program, label)
      if (location < 0)
        alert("Could not locate '" + label + "' in program")
      return location

    ##
    # Enable and upload a vertex array for attribute |label|. The vertex data is specified in
    # |buffer| with |dimension| number of components per vertex.
    #
    setVertexAttribArray: (label, dimension, buffer) ->
      if (@program == -1)
        alert("The program has been released")
      location = @getAttribLocation(label)
      @gl.enableVertexAttribArray(location)
      @gl.vertexAttribPointer(location, dimension, GLES20.GL_FLOAT, false, 0, buffer)

    getUniformLocation: (label) ->
      if (@program == -1)
        alert("The program has been released")
      location = @gl.getUniformLocation(@program, label)
      if (location < 0)
        alert("Could not locate uniform '" + label + "' in program")
      return location

    useProgram: ->
      if (@program == -1)
        alert("The program has been released")
      @gl.useProgram(@program)

    release: () ->
      console.log 'Deleting shader.'
      # Delete program, automatically detaching any shaders from it.
      if (@program != -1)
        @gl.deleteProgram(program)
        @program = -1

    _readShader: (shaderUrl) ->
      $http.get(shaderUrl).then (result) ->
        return
