'use strict';

/* Services */

var sailServices = angular.module('sailServices', ['ngResource']);

sailServices.service('Devices', ['$resource',
  function($resource){
    return $resource(
        "/api/:id/devices",
        {id: "@id" },
        {
            "update": {method: "PUT"}
        }
    );
}]);
