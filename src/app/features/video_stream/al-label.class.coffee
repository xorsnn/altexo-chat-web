
class AlLabel
  constructor: (@rendererData, @scene) ->
    @_init()
    return

  _init: () ->
    loader = new THREE.FontLoader()
    fileL = require('../../../fonts/Roboto_Regular.json')
    loader.load fileL, ( response ) =>
      font = response
      textGeo = new THREE.TextGeometry("some text", {
        font: font
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

      mesh = new THREE.Mesh( textGeo, material )
      @scene.add(mesh)
      return

    return

module.exports = AlLabel
