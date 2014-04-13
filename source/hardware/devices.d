module hardware.devices;

import std.conv;
import hardware.hardware;
import saillog, fifo, gpscoord;
import filter;

public import hardware.hwelement;

enum DeviceID : ubyte{
	Invalid,
	Sail,
	Helm,

	Gps,
	Roll,
	WindDir,
	Compass
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
		assert(m_min<=m_lastvalue && m_lastvalue<=m_max);
	}
}

/**
	Handles the helm orientation
*/
class Helm : HWAct!double {
	this(){
		m_id = DeviceID.Helm;
		m_min = -45;
		m_max = 45;
		m_init = 0;
		m_lastvalue=m_init;
	}

	invariant(){
		assert(m_min<=m_lastvalue && m_lastvalue<=m_max);
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
		m_min.longitude = -180;
		m_min.latitude = -90;
		m_max.longitude = 180;
		m_max.latitude = 90;
		m_init.longitude = 0;
		m_init.latitude = 0;
		m_lastvalue=m_init;
	}

	override{

		void ParseValue(ulong[2] data)
		out{
			assert(m_min.longitude<=m_values.front.value.longitude && m_values.front.value.longitude<=m_max.longitude);
			assert(m_min.latitude<=m_values.front.value.latitude && m_values.front.value.latitude<=m_max.latitude);
		}body{
			GpsCoord coord = GpsCoord(
				to!double((m_max.longitude-m_min.longitude)*data[0]/ulong.max),
				to!double((m_max.latitude-m_min.latitude)*data[0]/ulong.max)
				);
			m_values.Append(TimestampedValue!GpsCoord(Clock.currAppTick(), coord));
			m_lastvalue = Filter.Raw!GpsCoord(m_values);
		}

		void CheckIsOutOfService(){
			//May be wise to check if values are coherent
		}

		ulong[2] FormatValue(in GpsCoord value){
			return [cast(ulong)(value.latitude), cast(ulong)(value.longitude)];
		}
	}

	unittest {
		auto pos = GpsCoord(GpsCoord.toRad(37.3919331), GpsCoord.toRad(-122.043751));
		auto val = FormatValue(pos);
		assert(val[0]==cast(ulong)(pos.latitude) && val[1]==cast(ulong)(pos.longitude));
	}
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
		assert(m_min<=m_lastvalue && m_lastvalue<=m_max);
	}

	override void ParseValue(ulong[2] data)
	out{
		assert(m_min<=m_values.front.value && m_values.front.value<=m_max);
	}body{
		m_values.Append(TimestampedValue!float(Clock.currAppTick(),   to!float((m_max-m_min)*data[0]/ulong.max+m_min)  ));
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
		assert(m_min<=m_lastvalue && m_lastvalue<=m_max);
	}

	override void ParseValue(ulong[2] data)
	out{
		assert(m_min<=m_values.front.value && m_values.front.value<=m_max);
	}body{
		float fValue = to!float((m_max-m_min)*data[0]/ulong.max);
		if(fValue>180)
			fValue = 360-fValue;
		m_values.Append(TimestampedValue!float(Clock.currAppTick(),   fValue  ));
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
		assert(m_min<=m_lastvalue && m_lastvalue<=m_max);
	}

	override void ParseValue(ulong[2] data)
	out{
		assert(m_min<=m_values.front.value && m_values.front.value<=m_max);
	}body{
		m_values.Append(TimestampedValue!float(Clock.currAppTick(),   to!float((m_max-m_min)*data[0]/ulong.max)  ));
		m_lastvalue = Filter.TimedAvg!float(m_values);
	}

	override void CheckIsOutOfService(){
		//May be wise to check if values are coherent
	}
}