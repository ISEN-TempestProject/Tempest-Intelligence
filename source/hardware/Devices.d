module hardware.devices;

import hardware.hardware;

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

class Sail : HWAct!ushort {
	this(){
		m_id = DeviceID.Sail;
	}

}

class Roll : HWSens!double {
	this(){
		m_id = DeviceID.Roll;
	}
}