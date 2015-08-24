angular.module('ngMqtt', [])

.provider('mqtt', [() ->

#  $rootScope = $rootScopeProvider.$get[$rootScopeProvider.$get.length - 1]()
  _namespace = ''
  NS_STYLE = 'font-size: 13px; font-weight: bold; color: #606;'
  TOPIC_STYLE = 'font-size: 13px;'
  MSG_STYLE = 'font-size: 12px; font-style: italic; color: #777;'
  KEYWORD_STYLE = 'font-size: 13px; color: #008;'

  generateClientId = () ->
    length = 10
    possible = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    text = ((possible.charAt(Math.floor(Math.random() * possible.length))) for i in [1...length]).join ''
    'websocket/' + text

  connections = []

  mqtt =
    $get: ['$window', '$rootScope', '$q', ($window, $rootScope, $q) ->
      generateClientId: generateClientId,
      connect: (opts) ->
        console.log opts
        opts = opts || {}

        client = $window.mqtt.connect
          host: opts.host
          port: opts.port
          path: opts.path
          clientId: generateClientId()

        client.on 'message', (topic, message) ->
          # message is Buffer

          console.log '%c%s %ctopic:%c%s %cmessage:%c%s', NS_STYLE, _namespace, KEYWORD_STYLE, TOPIC_STYLE, topic, KEYWORD_STYLE, MSG_STYLE, message.toString()
          $rootScope.$emit _namespace + topic, message
          #client.end()

        $q (resolve, reject) ->
          client.on 'connect', () ->
            connections.push client
            resolve connections.length - 1
          client.on 'error', reject


      publish: (id, topic, message) ->
        if connections[id] && connections[id].connected
          connections[id].publish topic, message
        else
          throw new Error 'not connected'

      subscribe: (id, topic) ->
        if connections[id] && connections[id].connected
          connections[id].subscribe topic
        else
          throw new Error 'not connected'
      unsubscribe: (id, topic) ->
        if connections[id] && connections[id].connected
          connections[id].unsubscribe topic
        else
          throw new Error 'not connected'

      disconnect: (id) ->
        if connections[id] && connections[id].connected
          throw new Error 'not connected'
        else
          connections[id].end()
    ]

  Object.defineProperty mqtt, 'namespace',
    get: () ->
      _namespace
    set: (value) ->
      _namespace = value

  mqtt
])

.config(['mqttProvider', (mqttProvider) ->
  mqttProvider.namespace = 'my'
])

.controller('ctrl', ['$scope', 'mqtt', ($scope, mqtt) ->
#  mqtt.connect
#    broker: 'q.m2m.io'
#    port: 4483
#    path: '/mqtt'
#    username: 'cbefb25b-0c8c-4e70-a21d-9c381bc7e4bb'
#    password: 'a185b3de0fa03c1818ba0ac21bf173dd'
#    useSSL: true
#    keepalive: 30
#    timeout: 10
#    mqttVersion: 3.1
#    cleanSession: true

  connect = mqtt.connect
    host: 'localhost'
    port: 3000
    path: '/mqtt'
    username: ''
    password: ''
    useSSL: false
    keepalive: 30
    timeout: 10
    mqttVersion: 3.1
    cleanSession: true
  .then (id) ->
    mqtt.subscribe id, 'hello'
    mqtt.publish id, 'hello', 'world'
  , (error) -> console.error error


])


angular.module('ng-mqtt', [])
  .factory 'mqtt', ['$window', ($window) ->
  connections = {}

  generateClientId = () ->
    text = ''
    length = 10
    possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    text = (possible.charAt(Math.floor(Math.random() * possible.length)) for i in [1...length]) reduce (x, y) -> x + y
    'WEBSOCKET/'.concat text

  getEmitTopic = (event, id) ->
    'ThingFabricMqttWebSocketService'.concat(':').concat(event).concat(':').concat id

  {
    connect: (scope, opts) ->
      console.log opts
      connections[opts.connectionId] =
        opts: opts
        scope: scope
      client = new ($window.Paho.MQTT.Client)(String(ThingFabricConstants.mqttws.broker), Number(ThingFabricConstants.mqttws.port), generateClientId())
      connections[opts.connectionId].client = client

      client.onConnectionLost = (resp) ->
        if scope
          if typeof scope == 'function'
            return scope(getEmitTopic('connectionLost', opts.connectionId), resp)
          scope.$emit getEmitTopic('connectionLost', opts.connectionId), resp

      client.onMessageArrived = (message) ->
        if scope
          if typeof scope == 'function'
            return scope(getEmitTopic('messageArrived', opts.connectionId), resp)
          scope.$emit getEmitTopic('messageArrived', opts.connectionId), message

      client.connect
        userName: opts.username
        password: opts.password
        useSSL: ThingFabricConstants.mqttws.useSSL
        keepAliveInterval: opts.keepAliveInterval or ThingFabricConstants.mqttws.keepAliveInterval
        onSuccess: (resp) ->
          console.log 'Sucessfully made MqttWS connection for ID %s', opts.connectionId
          if scope
            if typeof scope == 'function'
              return scope(getEmitTopic('onSuccess', opts.connectionId), connectionId: opts.connectionId)
            scope.$emit getEmitTopic('onSuccess', opts.connectionId), connectionId: opts.connectionId
        onFailure: (resp) ->
          console.log 'Failed to make MqttWS connection!'
          console.log resp
          delete connections[opts.connectionId]
          # Both return codes appear to represent banned.
          if resp.errorCode and (resp.errorCode == 5 or resp.errorCode == 6)
            console.log 'Determining root cause of banning for Project %s!', $sanitize($routeParams.project_id)
            # Default text.
            delete $rootScope.bannedModalText
            # Lookup Project since we don't have it here.
            ThingFabricProjectsResource.show(
              project_id: $sanitize($routeParams.project_id)
              resources: []).then (resp) ->
            if resp.status != ThingFabricMessageService.jsend.SUCCESS
  # Just show banned message.
              return $rootScope.showBannedModal = true
            console.log 'Plan is %s', resp.data.plan
            planName = resp.data.plan
            plan = _.findWhere(ThingFabricConstants.plans, name: planName)
            # Did we exceed device limits?
            ThingFabricProjectDevicesResource.showMonthlyBillableCount(project_id: $sanitize($routeParams.project_id)).then (resp) ->
              if resp.status != ThingFabricMessageService.jsend.SUCCESS
  # Just show banned message.
                return $rootScope.showBannedModal = true
              if resp.data.count >= plan.max_devices
                console.log '%s is >= %s', resp.data.count, plan.max_devices
                $rootScope.bannedModalText = 1
                return $rootScope.showBannedModal = true
              # Did we publish a message on an invalid QoS level?
              # Get banned information from present. Check timestamps for last hour.
              ThingFabricProjectDevicesResource.present(
                project_id: $sanitize($routeParams.project_id)
                stuff: '$SYS'
                thing: 'bans').then (resp) ->

              isWithinHour = (clock) ->
                clock = parseInt(clock.toString().substring(0, 13))
                now = (new Date).getTime()
                console.log 'Is clock %s within hour of %s', clock, now
                difference = (now - clock) / 1000 / 60
                console.log 'Difference is %s minutes', difference
                if difference <= 60
                  return true
                false

              if resp.status != ThingFabricMessageService.jsend.SUCCESS
  # Just show banned message.
                return $rootScope.showBannedModal = true
              # Abused QoS 1 priveleges.
              if resp.data.whatevers['sent:rate:count'] and parseInt(resp.data.whatevers['sent:rate:count'].attributes.qos1) > parseInt(resp.data.whatevers['sent:limit:count'].attributes.qos1) and isWithinHour(parseInt(resp.data.whatevers['sent:rate:count'].attributes['qos1:clock']))
                $rootScope.bannedModalText = 2
                return $rootScope.showBannedModal = true
              # Abused QoS 2 priveleges.
              if resp.data.whatevers['sent:rate:count'] and parseInt(resp.data.whatevers['sent:rate:count'].attributes.qos2) > parseInt(resp.data.whatevers['sent:limit:count'].attributes.qos2) and isWithinHour(parseInt(resp.data.whatevers['sent:rate:count'].attributes['qos2:clock']))
                $rootScope.bannedModalText = 3
                return $rootScope.showBannedModal = true
              # If we didn't exceed device limits or publish a message on an invalid QoS level, we must have exceeded message limit.
              # Can we validate?
              $rootScope.bannedModalText = 4
              $rootScope.showBannedModal = true
            return
          if scope
            if typeof scope == 'function'
              return scope(getEmitTopic('onFailure', opts.connectionId), resp)
            scope.$emit getEmitTopic('onFailure', opts.connectionId), resp
    disconnect: (passedConnectionId) ->
      console.log 'Disconnecting MqttWS connection for ID %s', passedConnectionId
      try
        connections[passedConnectionId].client.disconnect()
        delete connections[passedConnectionId]
      catch error
        console.log 'MqttWS disconnect error'
    addLastWillMessage: (passedConnectionId, opts) ->
      message = new ($window.Paho.MQTT.Message)(opts.payload)
      message.qos = opts.qos or 0
      message.destinationName = opts.topic
      message.retained = opts.retain or false
      connections[passedConnectionId].client.willMessage = message
    subscribe: (passedConnectionId, opts) ->
      connections[passedConnectionId].client.subscribe opts.topic, qos: opts.qos or 0
    unsubscribe: (passedConnectionId, opts) ->
      connections[passedConnectionId].client.unsubscribe opts.topic
    publish: (passedConnectionId, opts) ->
      message = new ($window.Paho.MQTT.Message)(opts.payload)
      message.destinationName = opts.topic
      message.qos = Number(opts.qos or 0)
      message.retained = opts.retain or false
      connections[passedConnectionId].client.send message
  }
]