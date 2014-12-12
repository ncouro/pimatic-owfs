module.exports = (env) ->

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'
  
  # OWFS driver
  OwfsClient = require("owfs").Client

  HOST = "localhost"

  class OwfsPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("OwfsSensor", {
        configDef: deviceConfigDef.OwfsSensor,
        createCallback: (config) => return new OwfsSensor(config, framework)
      })

  class OwfsSensor extends env.devices.Sensor

    constructor: (@config, framework) ->
      @id = config.id
      @name = config.name
      # Connects on default port 4304
      # TODO should it be a global object?
      # TODO make HOST a configuration parameter
      @owfsConnection = new OwfsClient(HOST)
      Promise.promisifyAll(@owfsConnection)
      
      @attributes = {}
      # initialise all attributes
      for attr, i in @config.attributes
        do (attr) =>
          name = attr.name
          sensorPath = attr.sensorPath
          unit = attr.unit

          @attributes[name] = {
            description: "One-wire sensor for #{name}"
            type: "number"
            unit: unit
          }

          # Create a getter for this attribute
          getter = (=>
            # TODO do we need to catch exceptions here?
            return @owfsConnection.readAsync( sensorPath ).then( (res) =>
              return Number(res)
            )
          )

          # Call base class function to generate a getter with the adequate name
          @_createGetter(name, getter)

          setInterval( (=>
            getter().then( (value) =>
              @emit name, value
            ).catch( (error) =>
              env.logger.error "error updating value of OWFS sensor #{name}:", error.message
              env.logger.debug error.stack
            )
          ), attr.interval or 10000)
      super()

  # ###Finally
  # Create a instance of my plugin
  owfsPlugin = new OwfsPlugin
  # and return it to the framework.
  return owfsPlugin
