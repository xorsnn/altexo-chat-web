
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
      @_showLabel(false)
      @_createText()
      @_showLabel(true)


  _showLabel: (show = true) =>
    if @label
      if show
        unless @scene.getObjectById(@label.id)
          @scene.add(@label)
      else
        if @scene.getObjectById(@label.id)
          @scene.remove(@label)
    return

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

    @label = new THREE.Mesh( textGeo, material )
    @label.position.x = @rendererData.modification.position.x
    @label.rotation.y = @rendererData.modification.rotation.y
    return

module.exports = AlLabel
