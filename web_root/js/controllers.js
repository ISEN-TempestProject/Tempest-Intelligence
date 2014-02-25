'use strict';

/* Controllers */

var sailControllers = angular.module('sailControllers', []);


sailControllers.controller('mainCtrl', [
	function() {}
]);

sailControllers.controller('deviceCtrl', ['$scope', 'Devices',
	function($scope, Devices) {
	    $scope.devices = Devices.query();

	    $scope.toggleDevice = function(id) {
	    	var device = getById($scope.devices, id);
	    	device.emulated = !device.emulated;
		}

		$scope.deltaDevice = function(id, delta) {
	    	var device = Devices.get({},{'id':id});
	    	console.log('id : ' + id)
	    	device.value += delta;
	    	device.$save();
		}
	}
]);

sailControllers.controller('logCtrl', ['$scope', '$interval', 'Logs',
	function($scope, $interval, Logs) {
		$scope.logs = Logs.query();
		/*$interval(function(){
			$scope.logs += Logs.query();
		}, 1000);
	    $scope.logs += Logs.query();*/

	    $scope.level = '';
	}
]);
