import vibe.d;
import std.conv;
import std.process;
import api;

class Server
{

	HTTPServerSettings m_Settings;
	URLRouter m_Router;

	this(string[] adresses=[], ushort port=1337)
	{
		/************************
		*	SERVER SETTINGS
		*************************/
		m_Settings = new HTTPServerSettings;
		m_Settings.port = port;



		/************************
		*		ROUTERS
		*************************/
		m_Router = new URLRouter;
		registerRestInterface!ISailAPI(m_Router, API.Get(), "/api/");
		m_Router
			.get("/", serveStaticFile("web_root/index.html"))
			.get("*", serveStaticFiles("web_root/"));
	}

	/*
	*	Start server
	*/
	void start()
	{
		listenHTTP(m_Settings, m_Router);
	}

}