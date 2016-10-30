AlVideoStreamController = require './al-video-stream.ctrl.coffee'
AlVideoStreamConst = require './al-video-stream.const.coffee'

class AlVideoStreamDirective
  restrict: 'E'
  template: ''
  controller: AlVideoStreamController

angular
.module 'AltexoApp'
.constant 'AL_VIDEO_VIS', AlVideoStreamConst

angular.module('AltexoApp')
.directive 'alVideoStream',
  () ->
    new AlVideoStreamDirective
