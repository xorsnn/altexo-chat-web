THREE = require('three')

class AlLabel
  label: null
  labelText: ''
  font: null

  constructor: (@rendererData, @scene) ->
    @_init()
    return

  _init: () ->
    loader = new THREE.FontLoader()
    fileL = require('../../../fonts/Roboto_Regular.json')
    loader.load fileL, ( response ) =>
      @font = response
      unless @labelText == ''
        @updateText(@labelText)

    return

  updateText: (newText) =>
    @labelText = newText
    if @font
      @showLabel(false)
      @_createText()
      @showLabel(true)


  showLabel: (show = true) =>
    if @label
      if show
        @bind()
      else
        @unbind()
    return

  bind: ->
    unless @scene.getObjectById(@label.id)
      @scene.add(@label)

  unbind: ->
    if @scene.getObjectById(@label.id)
      @scene.remove(@label)

  _createText: () =>
    textGeo = new THREE.TextGeometry(@labelText, {
      font: @font
      size: 30 # size
      height: 2 #height
      curveSegments: 4 #curveSegments
      bevelThickness: 2 #bevelThickness
      bevelSize: 1.5 #bevelSize
      bevelEnabled: true #bevelEnabled
      material: 0
      extrudeMaterial: 1
    } )

    material = new THREE.MeshBasicMaterial( {
      color: 0x414141
      transparent: false
      blending: THREE.AdditiveBlending
    } )

    textGeo.computeBoundingBox()

    @label = new THREE.Mesh( textGeo, material )
    @label.position.x = (@rendererData.modification.position.x -
      (textGeo.boundingBox.max.x - textGeo.boundingBox.min.x) / 2)
    @label.position.y = 180
    @label.rotation.y = @rendererData.modification.rotation.y
    @label.position.z = (((textGeo.boundingBox.max.x - textGeo.boundingBox.min.x) *
      Math.sin(@rendererData.modification.rotation.y)) / 2)
    return

module.exports = AlLabel
