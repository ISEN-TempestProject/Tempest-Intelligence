module hardware.devices;

import std.conv;
import std.stdio : File;
import std.datetime;
import hardware.hardware;
import saillog, fifo, gpscoord;
import filter;
import config;

public import hardware.hwelement;

enum DeviceID : ubyte{
	Invalid,
	Sail,
	Helm,

	Gps,
	Roll,
	WindDir,
	Compass,
	Battery
}

/**
	Handles the sail tension
*/
class Sail : HWAct!ubyte {
	this(){
		m_id = DeviceID.Sail;
		m_min = ubyte.min;
		m_max = ubyte.max;
		m_init = 50;
		m_lastvalue=m_init;
	}

	invariant(){
		assert(m_min<=m_lastvalue && m_lastvalue<=m_max, "Value is out of bound");
	}


protected:
	override ulong[2] FormatValue(in ubyte value){
		return [cast(ulong)(value), 0];
	}
}

/**
	Handles the helm orientation
*/
class Helm : HWAct!float {
	this(){
		m_id = DeviceID.Helm;
		m_min = -45;
		m_max = 45;
		m_init = 0;
		m_lastvalue=m_init;
	}

	invariant(){
		assert(m_min<=m_lastvalue && m_lastvalue<=m_max, "Value is out of bound");
	}


protected:
	override ulong[2] FormatValue(in float value){
		return [cast(ulong)((value+45.0)*(ulong.max/90.0)), 0];
	}
}

//==============================================================================

/**
	Gets the GPS Position
*/
class Gps : HWSens!GpsCoord {
	this(){
		super(50);
		m_id = DeviceID.Gps;
		m_min.latitude = -90;
		m_max.latitude = 90;
		m_min.longitude = -180;
		m_max.longitude = 180;
		m_init.latitude = 0;
		m_init.longitude = 0;
		m_lastvalue=m_init;

		try{
			m_logfile.open(Config.Get!string("General", "GPSLogFile"), "a");
		}catch(Exception e){
			SailLog.Critical("Unable to log GPS data: ",e);
		}
	}

	invariant(){
		assert(m_min.latitude<=m_lastvalue.latitude && m_lastvalue.latitude<=m_max.latitude, "Value is out of bound");
		assert(m_min.longitude<=m_lastvalue.longitude && m_lastvalue.longitude<=m_max.longitude, "Value is out of bound");
	}

	override{

		void ParseValue(ulong[2] data)
		out{
			assert(m_min.latitude<=m_values.front.value.latitude && m_values.front.value.latitude<=m_max.latitude, "Value is out of bound");
			assert(m_min.longitude<=m_values.front.value.longitude && m_values.front.value.longitude<=m_max.longitude, "Value is out of bound");
		}body{
			GpsCoord coord = GpsCoord(
				GpsCoord.toRad(((m_max.latitude-m_min.latitude)*data[0]/ulong.max)+m_min.latitude),
				GpsCoord.toRad(((m_max.longitude-m_min.longitude)*data[1]/ulong.max)+m_min.longitude)
				);
			m_values.Append(TimestampedValue!GpsCoord(
				Clock.currAppTick(),
				coord
			));

			if(m_logfile.isOpen()){
				m_logfile.writeln(Clock.currTime.toSimpleString() ,"\t",coord);
			}

			m_lastvalue = Filter.Raw!GpsCoord(m_values);

		}

		void CheckIsOutOfService(){
			//May be wise to check if values are coherent
		}
	}

private:
	File m_logfile;
}

/**
	Gets the roll
*/
class Roll : HWSens!float {
	this(){
		super(10);
		m_id = DeviceID.Roll;
		m_min = -180.0;
		m_max = 180.0;
		m_init = 0.0;
		m_lastvalue=m_init;
	}

	invariant(){
		assert(m_min<=m_lastvalue && m_lastvalue<=m_max, "Value is out of bound");
	}

	override void ParseValue(ulong[2] data)
	out{
		assert(m_min<=m_values.front.value && m_values.front.value<=m_max, "Value is out of bound");
	}body{
		m_values.Append(TimestampedValue!float(
			Clock.currAppTick(),
			to!float((m_max-m_min)*data[0]/ulong.max)+m_min
		));
		m_lastvalue = Filter.TimedAvg!float(m_values);
	}

	override void CheckIsOutOfService(){
		//May be wise to check if values are coherent
	}
}

/**
	Gets the wind direction
*/
class WindDir : HWSens!float {
	this(){
		super(10);
		m_id = DeviceID.WindDir;
		m_min = -180;
		m_max = 180;
		m_init = 0;
		m_lastvalue=m_init;
	}

	invariant(){
		assert(m_min<=m_lastvalue && m_lastvalue<=m_max, "Value is out of bound");
	}

	override void ParseValue(ulong[2] data)
	out{
		assert(m_min<=m_values.front.value && m_values.front.value<=m_max, "Value is out of bound");
	}body{
		float fValue = to!float((m_max-m_min)*data[0]/ulong.max)+m_min;
		if(fValue>180)
			fValue = 360.0-fValue;

		m_values.Append(TimestampedValue!float(
			Clock.currAppTick(),
			fValue
		));
		m_lastvalue = Filter.TimedAvg!float(m_values);
	}

	override void CheckIsOutOfService(){
		//May be wise to check if values are coherent
	}

	float CalcAbsoluteWind(){
		float fCompass = Hardware.Get!Compass(DeviceID.Compass).value;
		float fValue = m_lastvalue+fCompass;
		if(fValue>360)
			fValue-=360;
		else if(fValue<0)
			fValue+=360;
		return fValue;
	}
}

/**
	Gets the heading
*/
class Compass : HWSens!float {
	this(){
		super(10);
		m_id = DeviceID.Compass;
		m_min = 0;
		m_max = 360;
		m_init = 0;
		m_lastvalue=m_init;
	}

	invariant(){
		assert(m_min<=m_lastvalue && m_lastvalue<=m_max, "Value is out of bound");
	}

	override void ParseValue(ulong[2] data)
	out{
		assert(m_min<=m_values.front.value && m_values.front.value<=m_max, "Value is out of bound");
	}body{
		m_values.Append(TimestampedValue!float(
			Clock.currAppTick(),
			to!float((m_max-m_min)*data[0]/ulong.max)+m_min
		));
		m_lastvalue = Filter.TimedAvg!float(m_values);
	}

	override void CheckIsOutOfService(){
		//May be wise to check if values are coherent
	}
}


/**
	Gets the battery voltage
*/
class Battery : HWSens!float {
	this(){
		super(10);
		m_id = DeviceID.Compass;
		m_min = 0;
		m_max = 15;
		m_init = 0;
		m_lastvalue=m_init;
	}

	invariant(){
		assert(m_min<=m_lastvalue && m_lastvalue<=m_max, "Value is out of bound");
	}

	override void ParseValue(ulong[2] data)
	out{
		assert(m_min<=m_values.front.value && m_values.front.value<=m_max, "Value is out of bound");
	}body{
		m_values.Append(TimestampedValue!float(
			Clock.currAppTick(),
			to!float((m_max-m_min)*data[0]/ulong.max)+m_min
		));
		m_lastvalue = Filter.Raw!float(m_values);

		//Battery voltage check
		if(m_lastvalue <= Config.Get!float("Battery", "CriticalVoltage"))
		{
			SailLog.Critical("Battery voltage is FAR TO LOW, you should rest : ",m_lastvalue,"v");
		}
		else if(m_lastvalue <= Config.Get!float("Battery", "LowVoltage"))
		{
			SailLog.Warning("Battery voltage is low : ",m_lastvalue,"v");
		}
	}

	override void CheckIsOutOfService(){
		//May be wise to check if values are coherent
	}
}