module gpscoord;

import std.regex;
import std.conv;


unittest {
	import std.exception;

	GpsCoord c = GpsCoord(GpsCoord.Unit.DecDeg, "42.25 -23.65");
	assert(c.longitude==42.25 && c.latitude==-23.65);

	assertThrown(c.Set(GpsCoord.Unit.DecDeg, "42.25 W23.65"));
}

/**
	GPS Coordinates, handling types conversions between dms, gps, ...
*/
struct GpsCoord {

	/*!
		@brief Constructor for decimal degrees
	*/
	this(in double longitude, in double latitude) {
		m_long = longitude;
		m_lat = latitude;
	}

	enum Unit{
		DecDeg, DegMinSec, GPS, UTM
	}

	/**
		Constructs the gps coordinates by parsing an expression
	*/
	this(Unit u, string expr){
		Set(u, expr);
	}

	/**
		Sets the gps coordinates by parsing an expression
	*/
	void Set(Unit u, string expr) {
		final switch(u){
			case Unit.DecDeg:
				auto results = match(expr, rgxDecDeg);
				if(results){
					m_long = to!double(results.captures[1]);
					m_lat = to!double(results.captures[2]);
				}
				else
					throw new Exception("'"~expr~"' does not match "~to!string(u)~" value");
				break;
			case Unit.DegMinSec:

				break;
			case Unit.GPS:

				break;
			case Unit.UTM:

				break;
		}
	}

	/**
		Converts the gps coordinates into the given representation
	*/
	string To(Unit u){
		final switch(u){
			case Unit.DecDeg:

				break;
			case Unit.DegMinSec:

				break;
			case Unit.GPS:

				break;
			case Unit.UTM:

				break;
		}
		return "";
	}

	/**
		Accessor for the value in decimal degrees
	*/
	@property{
		double longitude()const{return m_long;}
		void longitude(double value){m_long = value;}
		double latitude()const{return m_lat;}
		void latitude(double value){m_lat = value;}
	}

private:

	/**
		Precompiled regexes for types recognition
	*/
	@property static {
		enum rgxDecDeg = ctRegex!(r"^([0-9\.\-]+)\s+([0-9\.\-]+)\s*$");
		enum rgxDegMinSec = ctRegex!(r"^([N|S])\s*([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([E|W])\s*([0-9]+)\s+([0-9]+)\s+([0-9]+)$");
		enum rgxGPS = ctRegex!(r"^([N|S])\s*([0-9]+)\s+([0-9\.]+)\s+([E|W])\s*([0-9]+)\s+([0-9\.]+)\s*$");
		enum rgxUTM = ctRegex!(r"^([0-9]+)([N|S])\s*([0-9]+)\s+([0-9]+)$");
	}

	//In decimal degrees
	double m_long, m_lat;

}