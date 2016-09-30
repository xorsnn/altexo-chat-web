
# '- FLEXBOX',
# '- HTML5 VIDEO',
# '- WEBGL RENDERING',

class AlModernizr

  requirements: [
    {
      feature: Modernizr.webgl
      title: 'webgl'
    }
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
      title: 'cssanimations'
    }
    {
      feature: Modernizr.flexbox
      title: 'cssflexbox'
    }
    {
      feature: Modernizr.svgasimg
      title: 'svgasimg'
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

  check: () ->
    unsupportedFeatures = []
    for requirement in @requirements
      unless requirement.feature
        unsupportedFeatures.push(requirement.title)

    if unsupportedFeatures.length > 0
      message = [
        'SOME FEATURES ON THIS PAGE ARE',
        'NOT AVAILABLE IN YOUR BROWSER.',
        '',
        'FOLLOWING BROWSERS ARE SUPPORTED:'
        '- Chrome'
        '- Firefox'
        '- Opera'
        '',
        'PLEASE, CHECK THAT YOUR VERSION',
        'OF A BROWSER SUPPORTS:',
        ''
      ]
      message = message.concat(unsupportedFeatures)
      message = message.concat([
        '',
        'ALTEXO.COM'
      ])
      message = _.join(message, '\n')
      Raven.captureException('BROWSER doesn\'t support something\n' + _.join(unsupportedFeatures, '\n'))
      alert('\n\n' + message + '\n\n')
      return false
    else
      return true

module.exports = AlModernizr
