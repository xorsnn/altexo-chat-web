
# '- FLEXBOX',
# '- HTML5 VIDEO',
# '- WEBGL RENDERING',

angular.module('AltexoApp')
.constant 'AlModernizrConst',
  # set via environment
  excludeRequirements: AL_EXCLUDED_MODERNIZR_REQUIREMENTS.split(',')

  # features ids
  REQUESTANIMATIONFRAME: 0
  VIDEO: 1
  WEBGL: 2
  WEBSOCKETS: 3
  CSSANIMATIONS: 4
  CSSFLEXBOX: 5
  SVGASIMG: 6
  GETUSERMEDIA: 7
  PEERCONNECTION: 8

  requirements: [
    {
      feature: Modernizr.requestanimationframe
      title: 'requestanimationframe'
    }
    {
      feature: Modernizr.video
      title: 'video'
    }
    {
      feature: Modernizr.webgl
      title: 'webgl'
    }
    {
      feature: Modernizr.websockets
      title: 'websockets'
    }
    {
      feature: Modernizr.cssanimations
      title: 'css animations'
    }
    {
      feature: Modernizr.flexbox
      title: 'css flexbox'
    }
    {
      feature: Modernizr.svgasimg
      title: 'svg as img'
    }
    {
      feature: Modernizr.getusermedia
      title: 'webrtc getusermedia'
    }
    {
      feature: Modernizr.peerconnection
      title: 'webrtc peerconnection'
    }
  ]

.service 'AlModernizrService',
  class AlModernizr
    ### @ngInject ###
    constructor: (AlModernizrConst) ->
      @AlModernizrConst = AlModernizrConst
      return

    _getExcludedIndices: () ->
      indicesToExclude = []
      for excludedRequirement in @AlModernizrConst.excludeRequirements
        indicesToExclude.push(@AlModernizrConst[excludedRequirement])
      return indicesToExclude

    getUnsupportedFeatures: (excludeRequirements = []) ->
      unsupportedFeatures = []
      for i in [1...@AlModernizrConst.requirements.length]
        unless i in @_getExcludedIndices()
          requirement = @AlModernizrConst.requirements[i]
          unless requirement.feature
            unsupportedFeatures.push(requirement.title)
      return unsupportedFeatures

    check: (excludeRequirements = []) ->
      unsupportedFeatures = @getUnsupportedFeatures(excludeRequirements)
      if unsupportedFeatures.length > 0
        Raven.captureException('BROWSER doesn\'t support something\n' + _.join(unsupportedFeatures, '\n'))
        return false
      else
        return true
