angular.module('AltexoApp')
.service 'AuthTokenService', -> {
  auth_token: localStorage.getItem('al-auth-token')
}
