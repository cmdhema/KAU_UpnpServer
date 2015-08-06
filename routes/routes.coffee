socketHandler = require('../socket/socketHandler')

async = require 'async'
orm = require 'orm'

exports.doRoutes = (app) ->
  app.get '/', index
  app.post '/api/upnp/control/:gatewayId(\\d+)/:uuid/*', control
  app.post '/api/control/alarm', setAlarm


setAlarm = (req, res) ->
  console.log('alarm');
  sendToGateway req, res, req.body

sendToGateway = (req, res, body) ->
  async.waterfall [
    (callback) ->
      req.models.gateway.find ( err, gateways) ->
        console.log gateways[0].id
        console.log gateways[0].name
        callback err, gateways[0]
    (gateway, callback) ->
      selector =
        gateway : gateway.id
        uuid : 'KAU-Arduino'

      req.models.device.find selector, ( err, devices) ->
        if ( devices.length == 0 )
          log.info 'device not found'
        else
          callback err, gateway, devices[0]

    (gateway, device, callback) ->
      socketHandler.requestSetAlarm gateway.name, gateway.identifier, device.uuid, req.body, (err, message) ->
        callback err, message
  ], (err, message) ->
    if err
      log.warn err
      res.send 500, err
    else
      res.json message

control = (req, res)->
  log.info 'control'
  log.info req.body
  uuid = req.param('uuid')
  restPath = req.params[0]
  gatewayId = req.param('gatewayId')

  async.waterfall [
    (callback)->
      req.models.gateway.get gatewayId, (err, gateway)->
        callback err, gateway
    (gateway, callback)->
      console.log gateway.name
      socketHandler.requestDeviceControl gateway.name, gateway.identifier, uuid, restPath, req.body, (err, message)->
        callback err, message
  ], (err, message)->
    if err
      log.warn err
      res.send 500, err
    else
      res.json message

index = (req, res)->
  res.render 'index'

