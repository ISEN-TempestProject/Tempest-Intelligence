'use strict';

/* Controllers */

var sailControllers = angular.module('sailControllers', []);


sailControllers.controller('mainCtrl', [
	function() {}
]);

sailControllers.controller('deviceCtrl', ['$scope', '$interval', '$http', '$log',
	function($scope, $interval, $http, $log) {
	    
		$scope.getDevices = function(){	
		    $http.get('/api/devices')
			    .success(function(data, status, headers, config) {
			        $scope.devices = data;
			    })
			    .error(function(data, status, headers, config) {
			        $log.error('Can\'t reach devices.');
			    });
		}

	    $scope.toggleDevice = function(id) {
	    	var device = getById($scope.devices, id);
	    	device.emulated = !device.emulated;
	    	$scope.toogleEmulation(id, device.emulated);
		}

		$scope.deltaDevice = function(id, delta) {
	    	$http.get('/api/' + id + '/devices')
			    .success(function(data, status, headers, config) {
			    	data.value += delta;
			    	$http.post('/api/value', {"data" : JSON.stringify(data)})
			    		.success(function(data, status, headers, config) {
					        $log.info('POST received : ' + data);
					        $scope.getDevices();
					    })
					    .error(function(data, status, headers, config) {
					        $log.error('Can\'t post devices.');
					    });       
			    })
			    .error(function(data, status, headers, config) {
			        $log.error('Can\'t reach device with id ' + id);
			    });
		}

		$scope.toogleEmulation = function(id, isEmulated) {
	    	$http.get('/api/' + id + '/devices')
			    .success(function(data, status, headers, config) {
			    	data.emulated = isEmulated;
			    	$http.post('/api/emulation', {"data" : JSON.stringify(data)})
			    		.success(function(data, status, headers, config) {
					        $log.info('POST received : ' + data);
					        $scope.getDevices();
					    })
					    .error(function(data, status, headers, config) {
					        $log.error('Can\'t post devices.');
					    });       
			    })
			    .error(function(data, status, headers, config) {
			        $log.error('Can\'t reach device with id ' + id);
			    });
		}


		$scope.refreshDevices = -1;

		$scope.redev = function(){
			if($scope.refreshing !== undefined) $interval.cancel($scope.refreshing);
			
			if($scope.refreshDevices > 0) {
				$scope.refreshing = $interval(function(){
					$scope.getDevices();
				}, $scope.refreshDevices);
			}
		}

		$scope.getDevices();
		$scope.redev();
	}
]);

sailControllers.controller('logCtrl', ['$scope', '$interval', 'Logs',
	function($scope, $interval, Logs) {
		$scope.refreshLog = -1;

		$scope.relog = function(){
			if($scope.logging !== undefined) $interval.cancel($scope.logging);
			
			if($scope.refreshLog > 0) {
				$scope.logging = $interval(function(){
					$scope.logs = Logs.query();
				}, $scope.refreshLog);
			}
		}
		

		$scope.logs = Logs.query();
		$scope.relog();
	    $scope.level = '';
	}
]);


sailControllers.controller("GPSController", [ '$scope', function($scope) {
    angular.extend($scope, {
        defaults: {
            scrollWheelZoom: false
        }
    });
}]);