module filter;

import core.time;
import std.typecons;
import std.container;
import std.range;

public import std.datetime;
public import fifo;

alias TimestampedValue(T) = Tuple!(TickDuration,"time", T,"value");

static class Filter {

	public static{

		/**
			Returns the last value stored in the data
		*/
		T Raw(T)(ref Fifo!(TimestampedValue!T) data){
			return data.front().value;
		}

		/**
			Returns the average of all values stored in data
		*/
		T DumbAvg(T)(ref Fifo!(TimestampedValue!T) data){
			T ret = 0;
			size_t nElements = 0;
			foreach(ref cell ; data.elements){
				nElements++;
				ret += cell.value;
			}
			if(nElements>0)
				return ret/(nElements*1.0);
			return T.init;
		}

		/**
			Returns the time-weighted average of all values stored in data
		*/
		T TimedAvg(T)(ref Fifo!(TimestampedValue!T) data){
			T ret = 0;

			auto rng = data.elements.opSlice();
			if(!rng.empty){
				TickDuration dt = rng.back.time-rng.front.time;
				TimestampedValue!T last = rng.front;
				rng.popFront();

				if(!rng.empty){
					for( ; !rng.empty ; rng.popFront()){
						ret += last.value*(rng.front.time - last.time).length;
						last = rng.front;
					}
					ret /= dt.length;
				}
				else{
					return last.value;
				}
			}
			return ret;

		}

		/**
			Executes a kalman filter on the stored values
		*/
		T Kalman(T)(ref Fifo!(TimestampedValue!T) data){

			//TODO : implement this !

			return Raw!T(data);
		}

	}
}



unittest {
	import saillog;

	alias Tsvf = TimestampedValue!float;

	auto list = DList!Tsvf([Tsvf(TickDuration(10), 1), Tsvf(TickDuration(30), 2), Tsvf(TickDuration(60), 3), Tsvf(TickDuration(80), 4)]);
	auto fifo = Fifo!(Tsvf)(4, list);

	assert(Filter.Raw!float(fifo)==1);
	assert(Filter.DumbAvg!float(fifo)==2.5);
	assert(Filter.TimedAvg!float(fifo)==2.0);


	SailLog.Notify("Filter unittest done");
}