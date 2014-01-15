import vibe.d;
import std.conv;

shared static this()
{
	/************************
	*	SERVER SETTINGS
	*************************/
	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];



	/************************
	*		ROUTER
	*************************/
	auto router = new URLRouter;
	router.get("/", &index);



	/************************
	*	START SERVER
	*************************/
	listenHTTP(settings, router);


	logInfo("Now listening on port "~to!string(settings.port));
}


/*
*	Route : index page
*/
void index(HTTPServerRequest req, HTTPServerResponse res)
{
	res.render!("index.dt");
}
