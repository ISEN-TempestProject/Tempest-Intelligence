'use strict';

/* Controllers */

var sailControllers = angular.module('sailControllers', []);


sailControllers.controller('mainCtrl', ['$rootScope', '$scope', '$interval',
	function($rootScope, $scope, $interval) {
		$scope.refreshPeriod = 1000;

		$scope.refresh = function(){
			if($scope.refreshing !== undefined) $interval.cancel($scope.refreshing);
			
			if($scope.refreshPeriod > 0) {
				$scope.refreshing = $interval(function(){
					$scope.forceRefresh();
				}, $scope.refreshPeriod);
			}
		}

		$scope.forceRefresh = function(){
			$rootScope.getDevices();
			$rootScope.getLogs();
			$rootScope.getDC();
			$rootScope.getAutopilot();
			$rootScope.getSH();
		}

		$scope.refresh();
	}
]);

sailControllers.controller('deviceCtrl', ['$scope', '$rootScope', '$http', '$log',
	function($scope, $rootScope, $http, $log) {
	    
		$rootScope.getDevices = function(){	
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

		$rootScope.getDevices();
	}
]);

sailControllers.controller('logCtrl', ['$scope', '$rootScope', 'Logs',
	function($scope, $rootScope, Logs) {

		$rootScope.getLogs = function(){
			$scope.logs = Logs.query();
		}

		$rootScope.getLogs();
	    $scope.level = '';
	}
]);

sailControllers.controller('dcCtrl', ['$scope', '$rootScope', '$http', '$log',
	function($scope, $rootScope, $http, $log) {
	    
		$rootScope.getDC = function(){	
		    $http.get('/api/dc')
			    .success(function(data, status, headers, config) {
			        $scope.dc = data;
			    })
			    .error(function(data, status, headers, config) {
			        $log.error('Can\'t reach decision center.');
			    });
		}

	    $scope.toggleDC = function() {
	    	var dc = $scope.dc;
	    	dc.enabled = !dc.enabled;
	    	$http.post('/api/dc', {"status" : dc.enabled})
			    		.success(function(data, status, headers, config) {
					        $log.info('POST received : ' + data);
					        $rootScope.getDC();
					    })
					    .error(function(data, status, headers, config) {
					        $log.error('Can\'t post DC status.');
					    });   
		}

		$scope.setTargetPosition = function() {
	    	var data = '{"longitude" : '+$scope.dc.targetPosition.longitude+', "latitude" : '+$scope.dc.targetPosition.latitude+'}';

	    	$http.post('/api/targetposition', data)
    		.success(function(data, status, headers, config) {
		        $log.info('POST received : ' + data);
		        $rootScope.getDC();
		    })
		    .error(function(data, status, headers, config) {
		        $log.error('Can\'t post new Target Position.');
		    });
		}  

		$scope.setTargetHeading = function() {
	    	var data = '{"angle" : '+$scope.dc.targetHeading+'}';

	    	$http.post('/api/targetheading', data)
    		.success(function(data, status, headers, config) {
		        $log.info('POST received : ' + data);
		        $rootScope.getDC();
		    })
		    .error(function(data, status, headers, config) {
		        $log.error('Can\'t post new Target Heading.');
		    });
		}  

		$rootScope.getDC();
	}
]);

sailControllers.controller('autopilotCtrl', ['$scope', '$rootScope', '$http', '$log',
	function($scope, $rootScope, $http, $log) {
	    
		$rootScope.getAutopilot = function(){	
		    $http.get('/api/autopilot')
			    .success(function(data, status, headers, config) {
			        $scope.autopilot = data;
			    })
			    .error(function(data, status, headers, config) {
			        $log.error('Can\'t reach autopilot..');
			    });
		}

	    $scope.toggleAutopilot = function() {
	    	var autopilot = $scope.autopilot;
	    	autopilot.enabled = !autopilot.enabled;
	    	$http.post('/api/autopilot', {"status" : autopilot.enabled})
			    		.success(function(data, status, headers, config) {
					        $rootScope.getAutopilot();
					    })
					    .error(function(data, status, headers, config) {
					        $log.error('Can\'t post Autopilot status.');
					    });   
		}

		$rootScope.getAutopilot();
	}
]);

sailControllers.controller('shCtrl', ['$scope', '$rootScope', '$http', '$log',
	function($scope, $rootScope, $http, $log) {
	    
		$rootScope.getSH = function(){	
		    $http.get('/api/sh')
			    .success(function(data, status, headers, config) {
			        $scope.sh = data;
			    })
			    .error(function(data, status, headers, config) {
			        $log.error('Can\'t reach sail handler.');
			    });
		}

	    $scope.toggleSH = function() {
	    	var sh = $scope.sh;
	    	sh.enabled = !sh.enabled;
	    	$http.post('/api/sh', {"status" : sh.enabled})
			    		.success(function(data, status, headers, config) {
					        $rootScope.getSH();
					    })
					    .error(function(data, status, headers, config) {
					        $log.error('Can\'t post sail handler status.');
					    });   
		}

		$rootScope.getSH();
	}
]);