
angular.module('AltexoApp')

.service 'AccountsApi', ($q, $rest, $localStorage, AL_CONST) ->

  API_BASE = "#{AL_CONST.apiEndpoint}/api"

  ApiService = {

    startSession: (username, password) ->
      $rest("#{API_BASE}/users/auth/login/")
      .post({ username, password })
      .then (response) ->
        $localStorage.token = response.auth_token
        return response

    endSession: ->
      unless $localStorage.token
        return $q.reject(null)
      $rest("#{API_BASE}/users/auth/logout/")
      .auth($localStorage.token)
      .post()
      .then (response) ->
        $localStorage.token = null
        return response

    fetchProfile: ->
      unless $localStorage.token
        return $q.reject(null)
      $rest("#{API_BASE}/users/auth/me/")
      .auth($localStorage.token)
      .get()
      .catch (error) ->
        $localStorage.token = null
        return $q.reject(error)

    registerUser: (email, username, password) ->
      $rest("#{API_BASE}/users/auth/register/")
      .post({ email, username, password })

    activateUser: (uid, token) ->
      $rest("#{API_BASE}/users/auth/activate/")
      .post({ uid, token })

    resetPassword: (email) ->
      $rest("#{API_BASE}/users/auth/password/reset/")
      .post({ email })

    setPassword: (uid, token, new_password) ->
      $rest("#{API_BASE}/users/auth/password/reset/confirm/")
      .post({ uid, token, new_password })

    braintree: {
      clientToken: $rest("#{API_BASE}/shop/client-token/")
      paymentMethod: $rest("#{API_BASE}/shop/payment-method/")
      subscription: $rest("#{API_BASE}/shop/subscription/basic")
    }

  }

  Object.defineProperties(ApiService, {
    'token': { get: -> $localStorage.token }
  })
