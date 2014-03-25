import core.time;
import std.datetime;
import std.typecons;

// TickDuration date = Clock.currAppTick();

alias TimestampedValue(T) = Tuple!(TickDuration,"time", T,"value");

class Filter {
	override T Process(T)(const ref TimestampedValue!T[] data);


}


class FilterNothing : Filter {
	override T Process(T)(const ref TimestampedValue!T[] data){
		return data[$].value;
	}
}

class FilterAvg : Filter {
	override T Process(T)(const ref TimestampedValue!T[] data){
		T ret = 0;
		foreach(ref cell ; data){
			ret += cell.value;
		}
		return ret/(data.length*1.0);
	}
}


class FilterTimeAvg : Filter {
	override T Process(T)(const ref TimestampedValue!T[] data){
		T ret = 0;
		size_t size = data.length;
		for(int i=0 ; i<size-1 ; i++){
			ret += data[i].value*(data[i+1].time - data[i].time).hnsecs;
		}

		TickDuration dt = data[$].time - data[0].time;
		return ret/dt.hnsecs;
	}
}


//class FilterKalman : Filter {
//	override T Process(T)(const ref TimestampedValue!T[] data){
//		return T.init;
//	}
//}