module gpscoord;

import saillog;
import std.regex;
import std.conv;
import std.math;
import std.string;


/**
	GPS Coordinates, handling types conversions between dms, gps, ...
*/
struct GpsCoord {

	/*!
		@brief Constructor for radians
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
					m_lat = toRad(to!double(results.captures[1]));
					m_long = toRad(to!double(results.captures[2]));
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

					double lat = 0;
					lat += nD1;
					lat += (nM1/60.0);
					lat += (nS1/3600.0);
					if(cP1=="S" || cP1=="-")lat = -lat;
					m_lat = toRad(lat);

					double lon = 0;
					lon += nD2;
					lon += (nM2/60.0);
					lon += (nS2/3600.0);
					if(cP2=="W" || cP2=="-")lon = -lon;
					m_long = toRad(lon);
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

					double lat = 0;
					lat += nD1;
					lat += (fM1/60.0);
					if(cP1=="S" || cP1=="-")lat = -lat;
					m_lat = toRad(lat);

					double lon = 0;
					lon += nD2;
					lon += (fM2/60.0);
					if(cP2=="W" || cP2=="-")lon = -lon;
					m_long = toRad(lon);
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
				return format("%.15f %.15f", toDeg(m_lat), toDeg(m_long)).strip();
			case Unit.DegMinSec:
				double lat=toDeg(m_lat), lon=toDeg(m_long);

				char c1 = lat<0 ? 'S' : 'N';
				uint nD1 = to!uint(abs(lat));
				uint nM1 = to!uint(abs((abs(lat)-nD1)*60.0));
				float fS1 = abs((abs(lat)-nD1-nM1/60.0)*3600.0);

				char c2 = lon<0 ? 'W' : 'E';
				uint nD2 = to!uint(abs(lon));
				uint nM2 = to!uint(abs((abs(lon)-nD2)*60.0));
				float fS2 = abs((abs(lon)-nD2-nM2/60.0)*3600.0);

				return format("%c %d %d %.15f %c %d %d %.15f", c1, nD1, nM1, fS1, c2, nD2, nM2, fS2).strip();
			case Unit.GPS:
				double lat=toDeg(m_lat), lon=toDeg(m_long);

				char c1 = lat<0 ? 'S' : 'N';
				uint nD1 = to!uint(abs(lat));
				double fM1 = abs((abs(lat)-nD1)*60.0);

				char c2 = lon<0 ? 'W' : 'E';
				uint nD2 = to!uint(abs(lon));
				double fM2 = abs((abs(lon)-nD2)*60.0);

				return format("%c %d %.15f %c %d %.15f", c1, nD1, fM1, c2, nD2, fM2).strip();
		}
	}

	/**
		Accessor for the value in radian
	*/
	@property{
		double longitude()const{return m_long;}
		void longitude(double value){m_long = value;}
		double latitude()const{return m_lat;}
		void latitude(double value){m_lat = value;}
	}

	/**
		Gets the orthodromic distance (great circle) in meters to a point using haversine formula
	*/
	double GetDistanceTo(GpsCoord point)const{

		//Using Haversine formula
		// http://www.movable-type.co.uk/scripts/latlong.html
		double dLat = point.m_lat - m_lat;
		double dLon = point.m_long - m_long;
		double fLat1 = m_lat;
		double fLat2 = point.m_lat;

		double a = (sin(dLat/2.0))^^2.0 + cos(fLat1) * cos(fLat2) * (sin(dLon/2.0))^^2.0;

		double c = 2.0*atan2(sqrt(a), sqrt(1-a)); //Radian distance
		double d = EARTH_RADIUS_M * c; //To meters

		return d;
	}

	/**
		Gets the orthodromic distance (great circle) in meters to a point using the law of cosines
	*/
	double GetDistanceToCos(GpsCoord point){
		//Using spherical law of cosines

		return acos( sin(this.m_lat)*sin(point.m_lat) +
                   cos(this.m_lat)*cos(point.m_lat) * cos(point.m_long-this.m_long) ) * EARTH_RADIUS_M;
	}

	/**
		Gets the distance in meters to a point using the Pythagoras theorem (flat approximation)
	*/
	double GetDistanceToPyth(GpsCoord point){
		//Using Pythagoras (correct for short distances)
		double x = (point.m_long-m_long) * cos((point.m_lat+m_lat)/2);
		double y = point.m_lat-m_lat;
		return sqrt(x*x + y*y) * EARTH_RADIUS_M;
	}
	
	/**
		Gets the Bearing (compass direction, in degrees) to reach the given point using the great circle route (shortest)
		Note that start bearing and final bearing differs ! the great circle line is curved ;)
	*/
	double GetBearingTo(GpsCoord point)const{
		// http://www.movable-type.co.uk/scripts/latlong.html @ Bearing

		double rLat1 = m_lat;
		double rLat2 = point.m_lat;
		double rDLon = point.m_long-m_long;

		double y = sin(rDLon)*cos(rLat2);
		double x = cos(rLat1)*sin(rLat2) - sin(rLat1)*cos(rLat2)*cos(rDLon);

		return (toDeg(atan2(y, x))+360.0)%360.0;
	}
	
	/**
		Gets the Bearing (compass direction, in degrees) at the end of the route (great circle) from given point to this point (final bearing)
		Note that start bearing and final bearing differs ! the great circle line is curved ;)
	*/
	double GetBearingFrom(GpsCoord point)const{
		return (GetBearingTo(point)+180.0)%360.0;
	}

	/**
		Gets the distance in meters of the point from the route (great circle path) made with A and B
		The distance is signed, wether if the point is on the left/right side.
	*/
	double GetDistanceToRoute(GpsCoord A, GpsCoord B)const{
		// http://williams.best.vwh.net/avform.htm#Triangle
		return asin(sin(toRad(A.GetBearingTo(this)-A.GetBearingTo(B))) * sin(GetDistanceTo(A)/EARTH_RADIUS_M))*EARTH_RADIUS_M;
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
		float fLat1 = m_lat;
		float fLon1 = m_long;

		double fLat = asin( sin(fLat1)*cos(fDistance) + cos(fLat1)*sin(fDistance)*cos(fBearing) );
		double fLon = fLon1 + atan2( sin(fBearing)*sin(fDistance)*cos(fLat1), cos(fDistance)-sin(fLat1)*sin(fLat) );

		return GpsCoord(fLat,fLon);
	}

	/**
		Convert a radian angle to degrees
	*/
	static double toRad(in double fDegree){
		return fDegree*(PI/180.0);
	}

	/**
		Convert a degree angle to radians
	*/
	static double toDeg(in double fRad){
		return fRad*(180.0/PI);
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
	enum double EARTH_RADIUS_KM = 6371.0;
	enum double EARTH_RADIUS_M = EARTH_RADIUS_KM*1000.0;

	//In radians
	double m_lat, m_long;









	unittest {
		import std.exception;

		GpsCoord cRef = GpsCoord(toRad(37.3919331), toRad(-122.043751));

		//Creation and GPS parsing
		GpsCoord c = GpsCoord(GpsCoord.Unit.GPS, "37 23.516 -122 02.625");
		assert(abs(c.longitude-cRef.longitude)<0.001 && abs(c.latitude-cRef.latitude)<0.001);

		//Haversine test
		assert(abs(cRef.GetDistanceTo(GpsCoord(toRad(37.3919331), toRad(-121.043751)))-88344)<1);

		//Parsing tests
		c = GpsCoord(GpsCoord.Unit.DecDeg, "37.3919331 -122.043751");
		assert(c.latitude == toRad(37.3919331) && c.longitude == toRad(-122.043751));
		c = GpsCoord(GpsCoord.Unit.DegMinSec, "13 37 42 13 07 04");
		assert(abs(c.latitude-toRad(13.628333))<0.001 && abs(c.longitude-toRad(13.117778))<0.001);
		c = GpsCoord(GpsCoord.Unit.GPS, "37 23.516 -122 02.625");
		assert(abs(c.latitude-toRad(37.391933))<0.001 && abs(c.longitude+toRad(122.04375))<0.001);

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
		assert(abs(GpsCoord(toRad(12), toRad(23)).GetBearingTo(GpsCoord(toRad(1), toRad(91)))-93.7525)<0.001);
		assert(abs(GpsCoord(toRad(50.066389), toRad(-5.714722)).GetBearingTo(GpsCoord(toRad(58.643889), toRad(-3.07)))-9.119722)<0.001);


		//Destination points
		assert(abs(cOrig.GetDestinationPoint(0, 111195)		.GetDistanceTo(GpsCoord(toRad(1),	toRad(0))))	<0.1);
		assert(abs(cOrig.GetDestinationPoint(360, 111195)	.GetDistanceTo(GpsCoord(toRad(1),	toRad(0))))	<0.1);
		assert(abs(cOrig.GetDestinationPoint(90, 111195)	.GetDistanceTo(GpsCoord(toRad(0), 	toRad(1))))	<0.1);
		assert(abs(cOrig.GetDestinationPoint(180, 111195)	.GetDistanceTo(GpsCoord(toRad(-1), 	toRad(0))))	<0.1);
		assert(abs(cOrig.GetDestinationPoint(270, 111195)	.GetDistanceTo(GpsCoord(toRad(0), 	toRad(-1))))<0.1);
		assert(abs(cOrig.GetDestinationPoint(-90, 111195)	.GetDistanceTo(GpsCoord(toRad(0), 	toRad(-1))))<0.1);


		//Distance to route checks
		GpsCoord cA = GpsCoord(toRad(-5), 0);
		GpsCoord cB = GpsCoord(toRad(+5), 0);
		assert(abs(GpsCoord(0, toRad(1)).GetDistanceToRoute(cA, cB)-GpsCoord(0, 0).GetDistanceTo(GpsCoord(0, toRad(1))))<0.1);
		assert(abs(GpsCoord(0, toRad(-1)).GetDistanceToRoute(cA, cB)+GpsCoord(0, 0).GetDistanceTo(GpsCoord(0, toRad(1))))<0.1);


		SailLog.Notify("GpsCoord unittest done");
	}

}