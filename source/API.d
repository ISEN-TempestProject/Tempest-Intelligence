import vibe.http.rest;
import vibe.core.log;
import vibe.data.json;
import saillog;

interface ISailAPI
{
	// GET /devices
	Json getDevices();

	// GET /:id/devices
	Json getDevices(int id);

	// POST /:id/devices
	void addDevices(int id);
}


class API : ISailAPI
{

	Json getDevices()
	{
		return parseJsonString("
		[
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
		    },
		    {
		      \"id\": 4,
		      \"name\": \"Act-1\",
		      \"value\": 13.37,
		      \"delta\": 0.15,
		      \"lowCaption\": \"High\",
		      \"highCaption\": \"Low\",
		      \"emulated\" : false
		    },
		    {
		      \"id\": 5, 
		      \"name\": \"Act-2\",
		      \"value\": 22.29,
		      \"delta\": 12.37,
		      \"lowCaption\": \"Hi\",
		      \"highCaption\": \"Lo\",
		      \"emulated\" : true
		    }
		]");
	}	

	Json getDevices(int id=0)
	{
		return parseJsonString("{}");
	}

	void addDevices(int id){
		SailLog.Post("Device set : " ~ to!string(id));
	}
}