module gpscoord;

import saillog;
import std.regex;
import std.conv;
import std.math;
import std.string;


unittest {
	import std.exception;

	GpsCoord cRef = GpsCoord(37.3919331, -122.043751);

	//Creation and GPS parsing
	GpsCoord c = GpsCoord(GpsCoord.Unit.GPS, "37 23.516 -122 02.625");
	assert(abs(c.longitude-cRef.longitude)<0.0001 && abs(c.latitude-cRef.latitude)<0.0001);

	//Haversine test
	assert(abs(cRef.GetDistanceTo(GpsCoord(37.3919331, -121.043751))-88344)<1);

	//Parsing tests
	c = GpsCoord(GpsCoord.Unit.DecDeg, "37.3919331 -122.043751");
	assert(c.latitude == 37.3919331 && c.longitude == -122.043751);
	c = GpsCoord(GpsCoord.Unit.DegMinSec, "13 37 42 13 07 04");
	assert(abs(c.latitude-13.628333)<0.001 && abs(c.longitude-13.117778)<0.001);
	c = GpsCoord(GpsCoord.Unit.GPS, "37 23.516 -122 02.625");
	assert(abs(c.latitude-37.391933)<0.001 && abs(c.longitude+122.04375)<0.001);

	//Format/parse tests using haversine
	assert(abs(GpsCoord(GpsCoord.Unit.DecDeg, cRef.To(GpsCoord.Unit.DecDeg)).GetDistanceTo(cRef))<1);
	assert(abs(GpsCoord(GpsCoord.Unit.DegMinSec, cRef.To(GpsCoord.Unit.DegMinSec)).GetDistanceTo(cRef))<1);
	assert(abs(GpsCoord(GpsCoord.Unit.GPS, cRef.To(GpsCoord.Unit.GPS)).GetDistanceTo(cRef))<1);

	SailLog.Post("GpsCoord unittest done");
}

/**
	GPS Coordinates, handling types conversions between dms, gps, ...
*/
struct GpsCoord {

	/*!
		@brief Constructor for decimal degrees
	*/
	this(in double latitude, in double longitude) {
		m_lat = latitude;
		m_long = longitude;
	}

	enum Unit{
		DecDeg, DegMinSec, GPS
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
					m_lat = to!double(results.captures[1]);
					m_long = to!double(results.captures[2]);
				}
				else
					throw new Exception("'"~expr~"' does not match "~to!string(u)~" value");
				break;
			case Unit.DegMinSec:
				auto results = match(expr, rgxDegMinSec);
				if(results){
					string cP1 = results.captures[1];
					uint nD1 = to!uint(results.captures[2]);
					uint nM1  = to!uint(results.captures[3]);
					float nS1  = to!float(results.captures[4]);
					string cP2 = results.captures[5];
					uint nD2 = to!uint(results.captures[6]);
					uint nM2  = to!uint(results.captures[7]);
					float nS2  = to!float(results.captures[8]);

					m_lat = 0;
					m_lat += nD1;
					m_lat += (nM1/60.0);
					m_lat += (nS1/3600.0);
					if(cP1=="S" || cP1=="-")m_lat = -m_lat;

					m_long = 0;
					m_long += nD2;
					m_long += (nM2/60.0);
					m_long += (nS2/3600.0);
					if(cP2=="W" || cP2=="-")m_long = -m_long;
				}
				else
					throw new Exception("'"~expr~"' does not match "~to!string(u)~" value");
				break;
			case Unit.GPS:
				auto results = match(expr, rgxGPS);
				if(results){ 
					string cP1 = results.captures[1];
					uint nD1 = to!uint(results.captures[2]);
					double fM1  = to!double(results.captures[3]);
					string cP2 = results.captures[4];
					uint nD2 = to!uint(results.captures[5]);
					double fM2  = to!double(results.captures[6]);

					m_lat = 0;
					m_lat += nD1;
					m_lat += (fM1/60.0);
					if(cP1=="S" || cP1=="-")m_lat = -m_lat;

					m_long = 0;
					m_long += nD2;
					m_long += (fM2/60.0);
					if(cP2=="W" || cP2=="-")m_long = -m_long;
				}
				else
					throw new Exception("'"~expr~"' does not match "~to!string(u)~" value");

				break;
		}
	}

	/**
		Converts the gps coordinates into the given representation
	*/
	string To(Unit u){
		final switch(u){
			case Unit.DecDeg:
				return format("%15f %15f", m_lat, m_long).strip();
			case Unit.DegMinSec:
				char c1 = m_lat<0 ? 'S' : 'N';
				uint nD1 = to!uint(abs(m_lat));
				uint nM1 = to!uint(abs((abs(m_lat)-nD1)*60.0));
				float fS1 = abs((abs(m_lat)-nD1-nM1/60.0)*3600.0);

				char c2 = m_long<0 ? 'W' : 'E';
				uint nD2 = to!uint(abs(m_long));
				uint nM2 = to!uint(abs((abs(m_long)-nD2)*60.0));
				float fS2 = abs((abs(m_long)-nD2-nM2/60.0)*3600.0);

				return format("%c %d %d %15f %c %d %d %15f", c1, nD1, nM1, fS1, c2, nD2, nM2, fS2).strip();
			case Unit.GPS:
				char c1 = m_lat<0 ? 'S' : 'N';
				uint nD1 = to!uint(abs(m_lat));
				double fM1 = abs((abs(m_lat)-nD1)*60.0);

				char c2 = m_long<0 ? 'W' : 'E';
				uint nD2 = to!uint(abs(m_long));
				double fM2 = abs((abs(m_long)-nD2)*60.0);

				return format("%c %d %15f %c %d %15f", c1, nD1, fM1, c2, nD2, fM2).strip();
		}
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

	/**
		Gets the distance in meters from a point using haversine formula
	*/
	double GetDistanceTo(GpsCoord point){

		//Haversine formula
		// http://www.movable-type.co.uk/scripts/latlong.html
		double dLat = (point.latitude - latitude)*PI/180.0;
		double dLon = (point.longitude - longitude)*PI/180.0;
		double fLat1 = latitude*PI/180.0;
		double fLat2 = point.latitude*PI/180.0;

		double a = (sin(dLat/2.0))^^2.0 + cos(fLat1) * cos(fLat2) * (sin(dLon/2.0))^^2.0;

		double c = 2.0*atan2(sqrt(a), sqrt(1-a)); //Radian distance
		double d = EARTH_RADIUS * c; //To kilometers

		return d*1000.0;//convert in meters
	}
	double GetDistanceTo(GpsCoord A, GpsCoord B){
		return 0;
	}

private:

	/**
		Precompiled regexes for types recognition
	*/
	@property static {
		enum rgxDecDeg = ctRegex!(r"^([0-9\.\-]+)\s+([0-9\.\-]+)\s*$");
		enum rgxDegMinSec = ctRegex!(r"^([N|S|-|+]?)\s*([0-9]+)\s+([0-9]+)\s+([0-9\.]+)\s+([E|W|-|+]?)\s*([0-9]+)\s+([0-9]+)\s+([0-9\.]+)$");
		enum rgxGPS = ctRegex!(r"^([N|S|\-|\+]?)\s*([0-9]+)\s+([0-9\.]+)\s+([E|W|\-|\+]?)\s*([0-9]+)\s+([0-9\.]+)\s*$");
	}

	//Used in haversine formula
	enum double EARTH_RADIUS = 6371.0	;

	//In decimal degrees
	double m_lat, m_long;

}