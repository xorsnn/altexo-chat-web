
angular.module('AltexoApp')

.run ($rootScope, $location, User) ->
  $rootScope.$user = User

  $rootScope.$on '$routeChangeError', (ev, cur, prev, reason) ->
    if reason == User.NOT_AUTHENTICATED
      $location.path('/login')
    return

  return

.run (ScreenSharingExtension) ->
  # NOTE: require ScreenSharingExtension to receive
  # pings from extension just as app starts.

  return

.run ($rootScope, $location, AlModernizrService) ->
  # Run Modernizr check before entering route.
  # If check successfully passes do it only once.
  # Redirect to /not-supported page if check fails.

  endCheck = $rootScope.$on '$routeChangeStart', (ev, next) ->
    if AlModernizrService.check()
      return endCheck()
    unless '/not-supported' == next.$$route.originalPath
      ev.preventDefault()
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

    # <Alt+Key Up> : show stash
    # <Alt+Key Down> : hide stash
    $document.bind {
      keydown: (ev) ->
        if ev.altKey and ev.keyCode in [38, 40]
          $rootScope.showVideoStash(ev.keyCode == 38)
    }
    
  return
