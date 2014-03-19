module gpscoord;

import saillog;
import std.regex;
import std.conv;
import std.math;


unittest {
	import std.exception;

	GpsCoord cRef = GpsCoord(37.391933, -122.04375);

	GpsCoord c = GpsCoord(GpsCoord.Unit.GPS, "37 23.516 -122 02.625");
	assert(abs(c.longitude-cRef.longitude)<0.0001 && abs(c.latitude-cRef.latitude)<0.0001);

	//assertThrown(c.Set(GpsCoord.Unit.DecDeg, "42.25 W23.65"));

	SailLog.Warning(cRef.GetDistanceTo(GpsCoord(37.391933, -121.04375)));

	SailLog.Post("GpsCoord unittest done");
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

					m_long = 0;
					m_long += nD1;
					m_long += (nM1/60);
					m_long += (nS1/3600);
					if(cP1=="S" || cP1=="-")m_long = -m_long;

					m_lat = 0;
					m_lat += nD2;
					m_lat += (nM2/60);
					m_lat += (nS2/3600);
					if(cP2=="W" || cP2=="-")m_lat = -m_lat;
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

					m_long = 0;
					m_long += nD1;
					m_long += (fM1/60);
					if(cP1=="S" || cP1=="-")m_long = -m_long;

					m_lat = 0;
					m_lat += nD2;
					m_lat += (fM2/60);
					if(cP2=="W" || cP2=="-")m_lat = -m_lat;
				}
				else
					throw new Exception("'"~expr~"' does not match "~to!string(u)~" value");

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
				return to!string(m_long)~" "~to!string(m_lat);
			case Unit.DegMinSec:
				string sRet;
				if(m_long<0)sRet~="S";
				else sRet~="N";
				uint nD1 = to!uint(m_long);
				uint nM1 = to!uint((m_long-nD1)*60);
				float fS1 = (m_long-nD1-nM1/60)*3600;
				sRet~=to!string(nD1)~" "~to!string(nM1)~" "~to!string(fS1)~"\t";

				if(m_lat<0)sRet~="W";
				else sRet~="E";
				uint nD2 = to!uint(m_lat);
				uint nM2 = to!uint((m_lat-nD2)*60);
				float fS2 = (m_lat-nD2-nM2/60)*3600;
				sRet~=to!string(nD2)~" "~to!string(nM2)~" "~to!string(fS2);

				return sRet;
			case Unit.GPS:
				string sRet;
				if(m_long<0)sRet~="S";
				else sRet~="N";
				uint nD1 = to!uint(m_long);
				double fM1 = (m_long-nD1)*60;
				sRet~=to!string(nD1)~" "~to!string(fM1)~"\t";

				if(m_lat<0)sRet~="W";
				else sRet~="E";
				uint nD2 = to!uint(m_lat);
				double fM2 = (m_lat-nD2)*60;
				sRet~=to!string(nD2)~" "~to!string(fM2);

				return sRet;
			case Unit.UTM:

				return "";
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

	enum uint EARTH_RADIUS = 6371;
	double GetDistanceTo(GpsCoord point){

		//Haversine formula
		// http://www.movable-type.co.uk/scripts/latlong.html
		double dLat = (point.latitude - latitude)*PI/180;
		double dLon = (point.longitude - longitude)*PI/180;
		double fLat1 = latitude*PI/180;
		double fLat2 = point.latitude*PI/180;

		double a = (sin(dLat/2))^^2 + cos(fLat1) * cos(fLat2) * (sin(dLon/2))^^2;

		double c = 2*atan2(sqrt(a), sqrt(1-a)); 
		double d = EARTH_RADIUS * c;
		return d;
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
		enum rgxUTM = ctRegex!(r"^([0-9]+)([N|S])\s*([0-9]+)\s+([0-9]+)$");
	}

	//In decimal degrees
	double m_long, m_lat;

}