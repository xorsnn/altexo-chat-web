angular
.module 'AltexoApp'
.constant 'AL_CONST', {
  apiEndpoint: AL_API_ENDPOINT
  chatEndpoint: AL_CHAT_ENDPOINT
}
.constant 'AL_RTC', {
  config: {
    iceServers: [
      {url: 'stun:stun.l.google.com:19302'}
    ]
  }
  options: {
    optional: [
      { DtlsSrtpKeyAgreement: true }
    ]
  }
}
