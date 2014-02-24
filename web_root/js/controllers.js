'use strict';

/* Controllers */

var sailControllers = angular.module('sailControllers', []);

sailControllers.controller('sensorCtrl', ['$scope', 'Sensors',
	function($scope, Sensors) {
	    $scope.sensors = Sensors.query();

	    $scope.toggleSensor = function(id) {
	    	var sensor = getById($scope.sensors, id);
	    	sensor.emulated = !sensor.emulated;
		}

		$scope.deltaSensor = function(id, delta) {
	    	var sensor = Sensors.get({},{'id':id});
	    	console.log('id : ' + id)
	    	sensor.value += delta;
	    	sensor.$save();
		}
	}
]);

