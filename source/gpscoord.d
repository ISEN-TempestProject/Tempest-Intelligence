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

	//Bearing checks
	GpsCoord cOrig = GpsCoord(0, 0);
	assert(cOrig.GetBearingTo(GpsCoord(1, 0))==0.0);
	assert(cOrig.GetBearingTo(GpsCoord(0, 1))==90.0);
	assert(cOrig.GetBearingTo(GpsCoord(-1, 0))==180.0);
	assert(cOrig.GetBearingTo(GpsCoord(0, -1))==270.0);


	//Destination points
	assert(abs(cOrig.GetDestinationPoint(0, 111195).GetDistanceTo(GpsCoord(1, 0)))<0.1);
	assert(abs(cOrig.GetDestinationPoint(360, 111195).GetDistanceTo(GpsCoord(1, 0)))<0.1);
	assert(abs(cOrig.GetDestinationPoint(90, 111195).GetDistanceTo(GpsCoord(0, 1)))<0.1);
	assert(abs(cOrig.GetDestinationPoint(180, 111195).GetDistanceTo(GpsCoord(-1, 0)))<0.1);
	assert(abs(cOrig.GetDestinationPoint(270, 111195).GetDistanceTo(GpsCoord(0, -1)))<0.1);
	assert(abs(cOrig.GetDestinationPoint(-90, 111195).GetDistanceTo(GpsCoord(0, -1)))<0.1);

	//Distance to route checks
	GpsCoord cA = GpsCoord(-5, 0);
	GpsCoord cB = GpsCoord(+5, 0);
	SailLog.Warning("===================Distance to route checks");
	SailLog.Warning("Should be: ", GpsCoord(0, 0).GetDistanceTo(GpsCoord(0, 1)));
	SailLog.Warning("Calculated: ", GpsCoord(0, 1).GetDistanceToRoute(cA, cB)/1000.0);

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
	string To(Unit u)const{
		final switch(u){
			case Unit.DecDeg:
				return format("%.15f %.15f", m_lat, m_long).strip();
			case Unit.DegMinSec:
				char c1 = m_lat<0 ? 'S' : 'N';
				uint nD1 = to!uint(abs(m_lat));
				uint nM1 = to!uint(abs((abs(m_lat)-nD1)*60.0));
				float fS1 = abs((abs(m_lat)-nD1-nM1/60.0)*3600.0);

				char c2 = m_long<0 ? 'W' : 'E';
				uint nD2 = to!uint(abs(m_long));
				uint nM2 = to!uint(abs((abs(m_long)-nD2)*60.0));
				float fS2 = abs((abs(m_long)-nD2-nM2/60.0)*3600.0);

				return format("%c %d %d %.15f %c %d %d %.15f", c1, nD1, nM1, fS1, c2, nD2, nM2, fS2).strip();
			case Unit.GPS:
				char c1 = m_lat<0 ? 'S' : 'N';
				uint nD1 = to!uint(abs(m_lat));
				double fM1 = abs((abs(m_lat)-nD1)*60.0);

				char c2 = m_long<0 ? 'W' : 'E';
				uint nD2 = to!uint(abs(m_long));
				double fM2 = abs((abs(m_long)-nD2)*60.0);

				return format("%c %d %.15f %c %d %.15f", c1, nD1, fM1, c2, nD2, fM2).strip();
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
		Gets the orthodromic distance in meters from a point using haversine formula
	*/
	double GetDistanceTo(GpsCoord point)const{

		//Haversine formula
		// http://www.movable-type.co.uk/scripts/latlong.html
		double dLat = toRad(point.m_lat - m_lat);
		double dLon = toRad(point.m_long - m_long);
		double fLat1 = toRad(m_lat);
		double fLat2 = toRad(point.m_lat);

		double a = (sin(dLat/2.0))^^2.0 + cos(fLat1) * cos(fLat2) * (sin(dLon/2.0))^^2.0;

		double c = 2.0*atan2(sqrt(a), sqrt(1-a)); //Radian distance
		double d = EARTH_RADIUS_M * c; //To meters

		return d;
	}
	
	/**
		Gets the Bearing (compass direction, in degrees) to reach the given point
	*/
	double GetBearingTo(GpsCoord point)const{
		// http://www.movable-type.co.uk/scripts/latlong.html @ Bearing
		double y = sin(point.m_long-m_long)*cos(point.m_lat);
		double x = cos(m_lat)*sin(point.m_lat) - sin(m_lat)*cos(point.m_lat)*cos(point.m_long-m_long);

		return (toDeg(atan2(y, x))+360.0)%360.0;
	}

	/**
		Gets the distance in meters of the point from the route made with A and B
		The distance is signed, wether if the point is on the left/right side.
	*/
	double GetDistanceToRoute(GpsCoord A, GpsCoord B)const{
		// http://www.movable-type.co.uk/scripts/latlong.html @ Cross-track distance
		double fBearAToC = toRad(A.GetBearingTo(this));
		double fBearAToB = toRad(A.GetBearingTo(B));
		SailLog.Post("DistanceAC=", A.GetDistanceTo(this));

		return asin( sin(toRad(A.GetDistanceTo(this)*1000))*sin(fBearAToC-fBearAToB) )*EARTH_RADIUS_M;
		
		//double fBearAToC = toRad(A.GetBearingTo(this));
		//double fBearAToB = toRad(A.GetBearingTo(B));
		//return asin( sin(A.GetDistanceTo(this)/EARTH_RADIUS_M)*sin(fBearAToC-fBearAToB) )*EARTH_RADIUS_M;
	}

	//static GpsCoord GetRoutesIntersecton(GpsCoord a, GpsCoord b, GpsCoord A, GpsCoord B){
	//	//TODO: Needs implementation
	//}

	/**
		Gets the future position of the boat if it travels fDistance meters on its bearing
	*/
	GpsCoord GetDestinationPoint(double fBearing, float fDistance)const{

		fDistance /= EARTH_RADIUS_M;
		fBearing = toRad(fBearing);
		float fLat1 = toRad(m_lat);
		float fLon1 = toRad(m_long);

		double fLat = asin( sin(fLat1)*cos(fDistance) + cos(fLat1)*sin(fDistance)*cos(fBearing) );
		double fLon = fLon1 + atan2( sin(fBearing)*sin(fDistance)*cos(fLat1), cos(fDistance)-sin(fLat1)*sin(fLat) );

		return GpsCoord(toDeg(fLat),toDeg(fLon));
	}


private:
	static double toRad(double fDegree){
		return fDegree*(PI/180);
	}
	static double toDeg(double fRad){
		return fRad*(180/PI);
	}

	/**
		Precompiled regexes for types recognition
	*/
	@property static {
		enum rgxDecDeg = ctRegex!(r"^([0-9\.\-]+)\s+([0-9\.\-]+)\s*$");
		enum rgxDegMinSec = ctRegex!(r"^([N|S|-|+]?)\s*([0-9]+)\s+([0-9]+)\s+([0-9\.]+)\s+([E|W|-|+]?)\s*([0-9]+)\s+([0-9]+)\s+([0-9\.]+)$");
		enum rgxGPS = ctRegex!(r"^([N|S|\-|\+]?)\s*([0-9]+)\s+([0-9\.]+)\s+([E|W|\-|\+]?)\s*([0-9]+)\s+([0-9\.]+)\s*$");
	}

	//Used in haversine formula
	enum double EARTH_RADIUS_KM = 6371.0;
	enum double EARTH_RADIUS_M = EARTH_RADIUS_KM*1000.0;

	//In decimal degrees
	double m_lat, m_long;

}