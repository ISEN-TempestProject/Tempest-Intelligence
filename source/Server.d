import vibe.d;
import std.conv;
import std.process;
import API;

class Server
{

	HTTPServerSettings m_Settings;
	URLRouter m_Router;

	this(string[] adresses=[], ushort port=8080)
	{
		//Get IP Addresses
		auto ip = executeShell("/sbin/ifconfig | grep 'inet ad' | cut -d: -f2 | awk '{ print $1}'");
		string[] autoip =  ip.output.splitLines()[0..$];

		/************************
		*	SERVER SETTINGS
		*************************/
		m_Settings = new HTTPServerSettings;
		m_Settings.bindAddresses = autoip~adresses;
		m_Settings.port = port;



		/************************
		*		ROUTERS
		*************************/
		m_Router = new URLRouter;
		registerRestInterface(m_Router, new API());
		m_Router
			.get("/", &index)
			.get("*", serveStaticFiles("public/"));
	}

	/*
	*	Start server
	*/
	void start()
	{
		listenHTTP(m_Settings, m_Router);
	}

	/*
	*	Route : index page
	*/
	void index(HTTPServerRequest req, HTTPServerResponse res)
	{
		res.render!("index.dt");
	}

}