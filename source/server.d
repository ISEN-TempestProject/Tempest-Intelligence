module server;

import vibe.d;
import std.conv;
import std.process;
import config;
import api;

class Server
{

	HTTPServerSettings m_Settings;
	URLRouter m_Router;

	this()
	{
		/************************
		*	SERVER SETTINGS
		*************************/
		m_Settings = new HTTPServerSettings;
		m_Settings.port = config.Config.Get!ushort("WebServer","Port");



		/************************
		*		ROUTERS
		*************************/
		m_Router = new URLRouter;
		registerRestInterface(m_Router, API.Get(), "/api/");
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