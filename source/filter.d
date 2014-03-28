module filter;

import core.time;
import std.typecons;
import std.container;
import std.range;

public import std.datetime;
public import fifo;

// TickDuration date = Clock.currAppTick();

alias TimestampedValue(T) = Tuple!(TickDuration,"time", T,"value");



static class Filter {

	public static{

		T Raw(T)(ref Fifo!(TimestampedValue!T) data){
			return data.front().value;
		}

		T DumbAvg(T)(ref Fifo!(TimestampedValue!T) data){
			T ret = 0;
			foreach(ref cell ; data){
				ret += cell.value;
			}
			return ret/(data.length*1.0);
		}

		T TimedAvg(T)(ref Fifo!(TimestampedValue!T) data){
			T ret = 0;

			auto rng = data.elements.opSlice();

			if(!rng.empty){
				TimestampedValue!T last = rng.front;

				for( ; !rng.empty ; rng.popFront()){
					ret += last.value*(rng.front.time - last.time).hnsecs;
				}
			}

			//size_t size = data.length;
			//for(int i=0 ; i<size-1 ; i++){
			//	ret += rng[i].value*(rng[i+1].time - rng[i].time).hnsecs;
			//}

			TickDuration dt = rng.front.time - rng.back.time;
			return ret/dt.hnsecs;
		}

	}
}