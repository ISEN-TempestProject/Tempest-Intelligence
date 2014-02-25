'use strict';

/* App Module */

var sailApp = angular.module('sailApp', [
	'ngRoute',
	'sailControllers',
	'sailServices',
  'sailDirectives',
  'sailFilters'
]);


sailApp.config(['$routeProvider',
  function($routeProvider) {
    $routeProvider
      .when('/wide', {
        templateUrl: 'partials/wideView.html',
        controller: 'mainCtrl'
      })
      .when('/mobile', {
        templateUrl: 'partials/mobileView.html',
        controller: 'mainCtrl'
      })
      .otherwise({
        redirectTo: '/wide'
      });
  }]);
