'use strict';

/* Directives */

var sailDirectives = angular.module('sailDirectives', []);


sailDirectives.directive('devices', function () {
  return {
    restrict: 'A',
    replace: false,
    templateUrl:'partials/devices.html'
  }
});

sailDirectives.directive('logs', function () {
  return {
    restrict: 'A',
    replace: false,
    templateUrl:'partials/logs.html'
  }
});