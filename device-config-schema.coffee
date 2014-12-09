module.exports = {
  title: "OwfsSensor device config schemas"
  OwfsSensor: {
    title: "OwfsSensor config options"
    type: "object"
    extensions: ["xLink"]
    properties:
      attributes:
        description: "Attributes of the device"
        type: "array"
      interval:
        description: "Update interval in milliseconds"
        default: 10000
  }
}
