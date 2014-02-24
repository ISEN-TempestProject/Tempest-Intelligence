'use strict';

/* Services */

var sailServices = angular.module('sailServices', ['ngResource']);

sailServices.service('Sensors', ['$resource',
  function($resource){
    return $resource(
        "/api/:id/sensors",
        {id: "@id" },
        {
            "update": {method: "PUT"}
        }
    );
}]);
