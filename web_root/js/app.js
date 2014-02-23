'use strict';

/* App Module */

var sailApp = angular.module('sailApp', [
	'ngRoute',
	'sailControllers',
	'sailServices'
]);

sailApp.config(['$routeProvider',
  function($routeProvider) {
    $routeProvider
      .when('/wide', {
        templateUrl: 'partials/wideView.html',
        controller: 'sensorCtrl'
      })
      .when('/mobile', {
        templateUrl: 'partials/mobileView.html',
        controller: 'sensorCtrl'
      })
      .otherwise({
        redirectTo: '/wide'
      });
  }]);
