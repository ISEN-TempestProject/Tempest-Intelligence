import vibe.vibe;
import Server;

void main()
{
	Server server = new Server();
	server.start();
}
