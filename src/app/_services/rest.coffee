require('whatwg-fetch')

angular.module('AltexoApp')

.service '$rest', ($q) ->

  class RestFetch

    _method = (method) -> {
      method, headers: { 'Accept': 'application/json' }
    }

    _auth = (options, token) ->
      options.headers['Authorization'] = "Token #{token}"
      return options

    _data = (options, data) ->
      options.headers['Content-Type'] = 'application/json'
      options.body = JSON.stringify(data)
      return options

    constructor: (url) ->
      this._url = url
      this._token = null

    auth: (token) ->
      this._token = token
      return this

    get: ->
      options = _method('GET')
      options = _auth(options, this._token) if this._token
      return this._fetch(options)

    put: (data) ->
      options = _method('PUT')
      options = _data(options, data) if data
      options = _auth(options, this._token) if this._token
      return this._fetch(options)

    post: (data) ->
      options = _method('POST')
      options = _data(options, data) if data
      options = _auth(options, this._token) if this._token
      return this._fetch(options)

    delete: ->
      options = _method('DELETE')
      options = _auth(options, this._token) if this._token
      return this._fetch(options)

    _fetch: (options) ->
      $q.when(fetch(this._url, options))
      .then (response) ->
        if response.status == 204
          return null
        if response.ok
          return response.json()
        return response.json().then (data) ->
          Promise.reject(data)

  return (url) ->
    new RestFetch(url)
