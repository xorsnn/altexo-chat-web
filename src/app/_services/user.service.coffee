
angular.module('AltexoApp')

.service 'User', ($q, AccountsApi) ->
  profile = null
  ready = false

  $q.when(AccountsApi.fetchProfile())
  .then (_profile) ->
    profile = _profile
    ready = true
  .catch ->
    ready = true

  UserService = {}
  UserService.NOT_AUTHENTICATED = Object.create(null)

  UserService.authenticate = ->
    if profile == null
      return $q.reject(UserService.NOT_AUTHENTICATED)
    return profile

  UserService.login = (password, username) ->
    AccountsApi.startSession(password, username)
    .then ->
      AccountsApi.fetchProfile()
    .then (_profile) ->
      profile = _profile
      return true

  UserService.logout = ->
    AccountsApi.endSession()
    .then ->
      profile = null
      return true

  Object.defineProperties(UserService, {
    'isReady': {
      get: ->
        unless ready
          return  # *undefined*
        return true
    }
    'profile': { get: -> profile }
  })
