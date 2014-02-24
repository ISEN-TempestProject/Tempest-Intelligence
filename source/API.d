import vibe.http.rest;
import vibe.core.log;
import vibe.data.json;
import saillog;

interface ISailAPI
{
	// GET /sensors
	Json getSensors();

	// GET /:id/sensors
	Json getSensors(int id);

	// POST /:id/sensors
	void addSensors(int id);
}

// vibe.d takes care of all JSON encoding/decoding
// and actual API implementation can work directly
// with native types

class API : ISailAPI
{

	Json getSensors()
	{
		SailLog.Post("sensor all");
		return parseJsonString("[
		    {
		      \"id\": 1,
		      \"name\": \"Capt-1\",
		      \"value\": 42.1337,
		      \"delta\": 0.1,
		      \"lowCaption\": \"up\",
		      \"highCaption\": \"down\",
		      \"emulated\" : true
		    },
		    {
		      \"id\": 2,
		      \"name\": \"Capt-2\",
		      \"value\": 13.37,
		      \"delta\": 0.15,
		      \"lowCaption\": \"-\",
		      \"highCaption\": \"+\",
		      \"emulated\" : false
		    },
		    {
		      \"id\": 3,
		      \"name\": \"Capt-3\",
		      \"value\": 22.29,
		      \"delta\": 12.37,
		      \"lowCaption\": \"lower\",
		      \"highCaption\": \"higher\",
		      \"emulated\" : true
		    }
		]");
	}	

	Json getSensors(int id=0)
	{
		SailLog.Post("sensor : " ~ to!string(id));
		return parseJsonString("{}");
	}

	void addSensors(int id){
		SailLog.Post("Sensor set : " ~ to!string(id));
	}
}