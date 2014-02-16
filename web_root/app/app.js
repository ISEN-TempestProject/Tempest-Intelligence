steal(
	'jquery', 'can', 'can/control', 'can/model',
	'app/views/sensorsList.mustache',
	'app/fixtures',
function($, Can,  Control, Model, SensorsView){

	Sensors = Control({
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

	$(document).ready(function(){
	  $.when(Sensor.findAll()).then(
	    function(sensorResponse){
	      new Sensors('#sensors', {
	        sensors: sensorResponse[0]
	      });
	  });
	});

})