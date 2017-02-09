
angular.module('AltexoApp')

.factory 'httpRequestInterceptor',
(AuthTokenService) -> {
  request: (config) ->
    unless (token = AuthTokenService.auth_token)
      return config
    _.extend(config, {
      headers: _.defaults({
        'Authorization': "Token #{token}"
        }, config.headers)
    })
}
