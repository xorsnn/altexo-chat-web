require('../_constants/clean_webgl/al-flow-shaders.const.coffee')

angular.module('AltexoApp')
.factory 'AlShaderFactory',
($timeout, $window, $http, $q, FLOW_SHADERS) ->
  class AlShaderFactory
    constructor: (shaderList) ->
      @shaderList = shaderList
      @shaders = {}

    loadShaders: (shaderList = @shaderList) =>
      load = (index) =>
        @_loadShader(shaderList[index].path_frag).then (result) =>
          fragShader = @_parseShader(result)
          @_loadShader(shaderList[index].path_vert).then (result) =>
            vertShader = @_parseShader(result)
            @shaders[shaderList[index]['name']] = {
              vertShader: vertShader
              fragShader: fragShader
            }
            if index < shaderList.length - 1
              load(index+1)
            else
              $q.when(@shaders)
      load(0)

    composeShaders: (shaderList = @shaderList) =>
      load = (index) =>
        # @_loadShader(shaderList[index].path_frag).then (result) =>
        fragShader = @_parseShader(shaderList[index].path_frag)
        # @_loadShader(shaderList[index].path_vert).then (result) =>
        vertShader = @_parseShader(shaderList[index].path_vert)
        @shaders[shaderList[index]['name']] = {
          vertShader: vertShader
          fragShader: fragShader
        }
        if index < shaderList.length - 1
          load(index+1)
        else
          $q.when(@shaders)
      load(0)

    _parseShader: (shaderBody) ->
      replaceThreeChunkFn = (a, b, c) ->
        FLOW_SHADERS[b].toFixed(parseInt(c))

      shaderParse = (glsl) ->
        return glsl.replace(/ALTEXO_VAR\(\s?(\w+)\s?\,\s?(\d+)\s?\)/g, replaceThreeChunkFn)

      return shaderParse(shaderBody)

    _loadShader: (shaderPath) ->
      $http.get(shaderPath).then (result) ->
        $q.when(result.data)
