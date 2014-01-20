import vibe.http.rest;
import vibe.core.log;

interface IMyAPI
{
	// GET /:id/helm
	int getHelm(int id);
}

// vibe.d takes care of all JSON encoding/decoding
// and actual API implementation can work directly
// with native types

class API : IMyAPI
{
	private {
		int m_intHelmPos = 0;
	}

	int getHelm(int id=0)
	{
		m_intHelmPos += id;
		return m_intHelmPos;
	}
}