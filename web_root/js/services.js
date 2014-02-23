'use strict';

/* Services */

var sailServices = angular.module('sailServices', ['ngResource']);

sailServices.factory('Sensors', ['$resource',
  function($resource){
    return $resource('data/sensors.json', {}, {
      query: {method:'GET', isArray:true}
    });
}]);
