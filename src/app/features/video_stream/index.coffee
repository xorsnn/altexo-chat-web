
global.THREE = require('three')
AlVideoStreamController = require './al-video-stream.ctrl.coffee'
# AlVideoStreamConst = require './al-video-stream.const.coffee'

global.AL_VIDEO_CONST = require './al-video-stream.const.coffee'

class AlVideoStreamDirective
  restrict: 'E'
  template: ''
  controller: AlVideoStreamController

angular
.module 'AltexoApp'
.constant 'AL_VIDEO_VIS', AL_VIDEO_CONST

angular.module('AltexoApp')
.directive 'alVideoStream',
  () ->
    new AlVideoStreamDirective
