
angular.module('AltexoApp')
.controller 'AlNotSupportedCtrl',
  class AlNotSupportedCtrl
    unsupportedFeatures: []
    ### @ngInject ###
    constructor: (AlModernizrService) ->
      console.log 'AlNotSupportedCtrl'
      @unsupportedFeatures = AlModernizrService.getUnsupportedFeatures()
      console.log @unsupportedFeatures
      return
