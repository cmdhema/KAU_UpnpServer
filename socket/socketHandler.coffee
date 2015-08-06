net = require 'net'
async = require 'async'

class SocketHandler
  constructor: (@port) ->
    @port = 8484
    @clients = []
    @listeners = {}
    @key = 0

  connect: () ->
    net.createServer (sock) =>
      msg = '';
      log.info "CONNECTED #{sock.remoteAddress} #{sock.remotePort}"
      sock.setNoDelay(true)

      sock.on 'error', (err)->
        log.warn 'Socket ERROR'
        log.warn err
        log.warn err.stack
        delete sock.name
        delete sock.identifier

      sock.on 'message', (data) =>
#        log.info 'MESSAGE'
#        log.info data
        protocol = data
        switch(protocol.messageType)
          when 'Gateway'
            @gatewayHandler(protocol, sock)
          when 'AsyncUpnpMessage'
            @asyncUpnpMessageHandler(protocol, sock)
          when 'requestDeviceControl'
            @listeners[protocol.key].callback(null, protocol.data)
            delete @listeners[protocol.key]
          else
            log.warn "Another message type : #{protocol.messageType}"

      sock.on 'data', (data) =>
        msg += data.toString('utf8')
        i = msg.indexOf('\0')
        if ( i != -1 )
          sock.emit('message', JSON.parse(msg.substring(0, i)))
          msg = msg.substring(i + 1)

      sock.on 'close', (data) =>
        log.info "CLOSED #{sock.remoteAddress} #{sock.remotePort}"
        log.info sock.name
        log.info sock.identifier
        log.info @clients.indexOf(sock)
        @clients.splice(@clients.indexOf(sock), 1)
    .listen(@port)
    log.info('TCP server listening on port ' + @port)

  getSocketKey: () ->
    return ++@key

  getClientIndex: (name, identifier) ->
    for item, idx in @clients
      if item.identifier == identifier and item.name == name
        return idx
    return -1

  gatewayHandler: (protocol, sock)->
    log.info 'gatewayHandler'
    sock.name = protocol.name
    sock.identifier = protocol.identifier
    @clients.push(sock)
    selector =
      name: protocol.name,
      identifier: protocol.identifier

    async.waterfall [
      (callback)->
        DB.gateway.find selector, (err, gateways)->
          callback err, gateways
      (gateways, callback)->
        protocol.online = true
        if (gateways.length == 0)
          DB.gateway.create protocol, (err, gateway)->
            callback err, gateway
        else
          gateways[0].name = protocol.name
          gateways[0].identifier = protocol.identifier
          gateways[0].online = true
          gateways[0].save (err, gateway)->
            callback err, gateway
    ], (err, gateway)->
      if err
        log.warn err
        sock.write JSON.stringify({error: 'gatewayHandler error'}) + '\n'
      else
        sock.gateway = gateway

  asyncUpnpMessageHandler: (protocol, sock)->
    selector =
      name: sock.name
      identifier: sock.identifier
    uuid = if protocol.type != "DeviceEvent"
    then protocol.data.identity.udn.identifierString
    else protocol.data.udn
    console.log uuid

    async.waterfall [
      (callback)->
        DB.gateway.find(selector).run (err, gateways)->
          callback err, gateways

      (gateways, callback)->
        if gateways.length != 1
          callback "gateway length is #{gateways.length}. I want gateway length is 1"
        else
          deviceQuery =
            gateway: gateways[0].id
            uuid: uuid

          DB.device.find(deviceQuery).run (err, devices)->
            callback err, devices, gateways[0]

      (devices, gateway, callback)->
        if ( devices.length == 0 )
          device =
            uuid: uuid
            gateway: gateway.id
          DB.device.create device, (err, newDevice)->
            callback err, newDevice, gateway
        else if (devices.length != 1)
          callback("device length not 1");
        else
          callback(null, devices[0], gateway)
    ], (err, result) ->
      if err
        log.warn err

  requestSetAlarm: (name, identifier, uuid, data, callback) ->
    index = @getClientIndex name, identifier
    if index < 0
      return callback 500

    this.write name, identifier,
      responseType: 'requestSetAlarm',
      uuid: uuid
      data: data

  requestDeviceControl: (name, identifier, uuid, data, callback) ->
    index = @getClientIndex name, identifier
    if index < 0
      return callback 500

    key = this.getSocketKey()
    @listeners[key] =
      key: key,
      name: name,
      identifier: identifier,
      messageType: 'requestDeviceControl',
      uuid: uuid,
      query: query,
      data: data,
      callback: callback

    this.write name, identifier,
      key: key,
      responseType: 'requestDeviceControl'
      uuid: uuid
      query: query
      data: data
  write: (name, identifier, object)->
    selectedClients = @clients.filter (item)->
      if( item.identifier == identifier && item.name == name )
        return item
    selectedClients[0].write(JSON.stringify(object) + '\n')

singleton = {}
singleton.instance = null

singleton.getInstance = ()->
  if(this.instance == null)
    this.instance = new SocketHandler()
  return this.instance

module.exports = singleton.getInstance()
