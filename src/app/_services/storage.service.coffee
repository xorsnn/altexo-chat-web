
class Storage
  set: (key, value, usePrefix = true) ->
    newKey = @_addPrefix(key, usePrefix)
    localStorage.setItem(newKey, angular.toJson(value))
    return

  get: (key, usePrefix = true) ->
    newKey = @_addPrefix(key, usePrefix)
    return angular.fromJson(localStorage.getItem(newKey))

  remove: (key, usePrefix = true) ->
    newKey = @_addPrefix(key, usePrefix)
    localStorage.removeItem(newKey)
    return

  clear: () ->
    localStorage.clear()
    return

  # prefix with "al" namespace
  _addPrefix: (key, usePrefix = true) ->
    newKey = ''

    if (usePrefix)
      newKey = _.camelCase('al-' + key)
    else
      newKey = key

    return newKey

angular.module('AltexoApp')
.service('Storage', Storage)
