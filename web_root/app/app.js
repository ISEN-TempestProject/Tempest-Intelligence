steal(
	'jquery', 'can', 'can/control', 'can/model',
	'app/views/sensorsList.mustache', 'app/views/actuatorsList.mustache',
	'app/fixtures',
function($, Can,  Control, Model, SensorsView, ActuatorsView){

	/*
	*	SENSORS
	*/

	Sensors = Control.extend({
	  init: function(){
	    this.element.html( Can.view( SensorsView, {sensors : this.options.sensors} ) );
	  },

	  '.sensor .onoffswitch-checkbox click' : function(el, ev){
	  	el.parent().parent().parent().find('button').each(function(){
	  		var el$ = $(this);
	  		el$.prop('disabled', !el.prop('checked'));
	  	});
	  }
	});

	Sensor = Model({
	  findAll: 'GET /sensors',
	  create  : "POST /sensors",
	  update  : "PUT /sensors/{id}",
	  destroy : "DELETE /sensors/{id}"
	},{});


	/*
	*	ACTUATORS
	*/

	Actuators = Control.extend({
	  init: function(){
	    this.element.html( Can.view( ActuatorsView, {actuators : this.options.actuators} ) );
	  },

	  '.actuator .onoffswitch-checkbox click' : function(el, ev){
	  	el.parent().parent().parent().find('button').each(function(){
	  		var el$ = $(this);
	  		el$.prop('disabled', !el.prop('checked'));
	  	});
	  }
	});

	Actuator = Model({
	  findAll: 'GET /actuators',
	  create  : "POST /actuators",
	  update  : "PUT /actuators/{id}}",
	  destroy : "DELETE /actuators/{id}"
	},{});


	/*
	*	Document ready
	*/

	$(document).ready(function(){
	  $.when(Sensor.findAll()).then(
	    function(sensorResponse){
	      new Sensors('#sensors', {
	        sensors: sensorResponse[0]
	      });
	  });
	  $.when(Actuator.findAll()).then(
	    function(actuatorResponse){
	      new Actuators('#actuators', {
	        actuators: actuatorResponse[0]
	      });
	  });
	});

})