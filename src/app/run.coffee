
angular.module('AltexoApp')

.run (ScreenSharingExtension) ->
  # NOTE: require ScreenSharingExtension to receive
  # pings from extension just as app starts.
  return

.run ($rootScope, $location, AlModernizrService) ->
  $rootScope.$on '$routeChangeStart', (event, next, current) ->
    unless next.$$route.originalPath == '/not-supported'
      unless AlModernizrService.check()
        event.preventDefault()
        $location.path('/not-supported')
    return
  return

.run ($rootScope, $window, $document) ->
  # Bunch of helpers.

  $rootScope.$listenObject = (obj, name, handler) ->
    endListener = obj.$on(name, handler)
    this.$on('$destroy', endListener)

  $rootScope.$listenDocument = (name, handler) ->
    this.$on '$destroy', ->
      $document.off(name, handler)
    $document.on(name, handler)

  $rootScope.$listenWindow = (name, handler) ->
    this.$on '$destroy', ->
      $window.removeEventListener(name, handler)
    $window.addEventListener(name, handler, false)

  $rootScope.$runAnimation = (render) ->
    _rafid = null
    this.$on '$destroy', ->
      unless _rafid == null
        cancelAnimationFrame(_rafid)
    animate = ->
      _rafid = requestAnimationFrame(animate)
      render()

  return

.run ($rootScope, $document) ->

  $rootScope.showVideoStash = (show) ->
    $document.find('#videostash')
      .css('display', if show then 'block' else 'none')
  
  if DEBUG == 'true'

    $document.bind {
      keydown: (ev) ->
        if ev.altKey and ev.keyCode in [38, 40]
          $rootScope.showVideoStash(ev.keyCode == 38)
    }
    
  return
