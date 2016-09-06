AlVideoStreamController = require('./al-video-stream.ctrl.coffee')

class AlVideoStreamDirective
  restrict: 'E'
  template: ''
  controller: AlVideoStreamController

angular.module('AltexoApp')
.directive 'alVideoStream',
  () ->
    new AlVideoStreamDirective
