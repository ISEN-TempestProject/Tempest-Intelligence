'use strict';

/* Filters */

var sailFilters = angular.module('sailFilters', []);


sailFilters.filter('logLevelCSS', function() {
	return function(input) {
		switch(input){
			case 'Warning':
				return "list-group-item-warning";
			case 'Critical':
				return "list-group-item-danger";
			case 'Success':
				return "list-group-item-success";
			case 'Notify':
				return "list-group-item-info";
			case 'Post':
				return "list-group-item-default";
			default:
				return "list-group-item-default";
		}
	};
})
.filter('removeGPS', [function(){
    return function(input){
        var ret = [];
        for(var i = 0 ; i<input.length ; i++){
            if(input[i].id != 3) ret.push(input[i]);
        }
        return ret;
    };
}]);