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
		registerRestInterface!ISailAPI(m_Router, new API(), "/api/");
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