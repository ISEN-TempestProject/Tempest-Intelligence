steal('can/util/fixture', 
  function(Fixture){

  /*
  * SENSORS
  */

  var SENSORS = [
    {
      id: 1,
      name: 'Capt-1',
      value: 42.1337,
      lowCaption: '<',
      highCaption: '>',
      emulated : true
    },
    {
      id: 2,
      name: 'Capt-2',
      value: 13.37,
      lowCaption: '-',
      highCaption: '+',
      emulated : false
    },
    {
      id: 3,
      name: 'Capt-3',
      value: 22.29,
      lowCaption: 'lower',
      highCaption: 'higher',
      emulated : true
    }
  ];

  Fixture('GET /sensors', function(){
    return [SENSORS];
  });
   
  var id= 4;
  Fixture("POST /sensors", function(){
    return {id: (id++)};
  });
   
  Fixture("PUT /sensors/{id}", function(){
    return {};
  });
   
  Fixture("DELETE /sensors/{id}", function(){
    return {};
  });

  /*
  * ACTUATORS
  */

  var ACTUATORS = [
    {
      id: 1,
      name: 'Act-1',
      value: 1337.42,
      lowCaption: 'Hi',
      highCaption: 'Lo',
      emulated : false
    },
    {
      id: 2,
      name: 'Act-2',
      value: 73.13,
      lowCaption: 'Hi',
      highCaption: 'Ho',
      emulated : true
    }
  ];

  Fixture('GET /actuators', function(){
    return [ACTUATORS];
  });
   
  id= 3;
  Fixture("POST /actuators", function(){
    return {id: (id++)};
  });
   
  Fixture("PUT /actuators/{id}", function(){
    return {};
  });
   
  Fixture("DELETE /actuators/{id}", function(){
    return {};
  });


});
