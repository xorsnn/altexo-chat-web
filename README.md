# Altexo (web client) #

Holographic chat application. While video conferencing is somewhat mainstream, the next major jump is to add a new dimension to make collaboration more authentic and fun. Using Altexo, you can communicate with holograms.

## Other components ##

- [altexo desktop application](https://github.com/xorsnn/altexo-desktop-app)
- [altexo signal server](https://github.com/xorsnn/altexo-signal-server)

## Examples ##
### WebVR experience ###

Here is an example of WebVR client. Volumetric data is transmitted over the internet using WebRTC. The video is recorded using Samsung galaxy 7.
![WebVR altexto example](https://github.com/xorsnn/altexo-chat-web/blob/master/static/WebVR.gif)

### Web client ###

![Web client example](https://github.com/xorsnn/altexo-chat-web/blob/master/static/web.gif)

### Other resources ###
See more demos and examples on the [youtube channel](https://youtu.be/hpWKITMRGRw)

## Build ##
```
npm install
npm install -g bower
bower install
npm run build
```

## Desktop app ##
The [desktop application](https://github.com/xorsnn/altexo-desktop-app) is responsible for interacting with the equipment such as Microsoft Kinect or Intel RealSense and encoding of volumetric data.
