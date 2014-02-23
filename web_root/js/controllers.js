'use strict';

/* Controllers */

var sailControllers = angular.module('sailControllers', []);

sailControllers.controller('sensorCtrl', ['$scope', 'Sensors',
	function($scope, Sensors) {
	    $scope.sensors = Sensors.query();
}]);

