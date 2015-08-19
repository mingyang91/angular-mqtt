/**
 * Created by famer.me on 15-8-19.
 */
'use strict';

describe('json-formatter', function () {
  var scope, $compile, $rootScope, element, fakeModule, thumbnailProviderConfig;

  beforeEach(module('ngMqtt'));
  //beforeEach(inject(function(_$rootScope_, _$compile_) {
  //  $rootScope = _$rootScope_;
  //  scope = $rootScope.$new();
  //  $compile = _$compile_;
  //}));

  afterEach(function () {

  });

  describe('angular-mqtt', function () {
    it('generateClientId', inject(function (mqtt) {
      expect(mqtt.generateClientId()).toMatch(/^websocket[/]/);
      mqtt.connect({
        broker: 'q.m2m.io',
        port: 4833,
        path: '/mqtt',
        username: 'cbefb25b-0c8c-4e70-a21d-9c381bc7e4bb',
        password: 'a185b3de0fa03c1818ba0ac21bf173dd',
        useSSL: true,
        keepalive: 30,
        mqttVersion: 3.1
      })
    }));
  });
});