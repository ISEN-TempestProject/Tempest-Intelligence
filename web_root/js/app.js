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
        controller: 'deviceCtrl'
      })
      .when('/mobile', {
        templateUrl: 'partials/mobileView.html',
        controller: 'deviceCtrl'
      })
      .otherwise({
        redirectTo: '/wide'
      });
  }]);
