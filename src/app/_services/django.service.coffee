
errorTags = [
  [/unique/i, 'unique']
  [/pass.+match/i, 'verify']
]

angular.module('AltexoApp')

.service '$django', -> {

  errorToAngularMessages: (error) ->
    foldMessages = ($error, message) ->
      messageTag = 'other'
      for [regex, tag] in errorTags
        if message.match(regex)
          messageTag = tag
          break
      $error[messageTag] = message
      return $error
    foldErrors = (result, key) ->
      result[key] = { $error: error[key].reduce(foldMessages, {}) }
      return result
    return Object.keys(error).reduce(foldErrors, {})

}
