import vibe.vibe;
import Server;

void main()
{
	if (!finalizeCommandLineOptions())
		return;

	Server server = new Server();
	server.start();

	lowerPrivileges();
	runEventLoop();
}
