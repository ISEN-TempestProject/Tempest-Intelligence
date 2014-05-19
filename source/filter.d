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
			if(data.elements.empty)
				return GetZero!T();
			
			return data.front().value;
		}

		/**
			Returns the average of all values stored in data
		*/
		T DumbAvg(T)(ref Fifo!(TimestampedValue!T) data){
			T ret = GetZero!T();

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
			T ret = GetZero!T();

			auto rng = data.elements.opSlice();
			if(!rng.empty){
				TickDuration dt = rng.back.time-rng.front.time;
				TimestampedValue!T last = rng.front;
				rng.popFront();

				if(!rng.empty){
					for( ; !rng.empty ; rng.popFront()){
						ret = ret + (last.value*(rng.front.time - last.time).length);
						last = rng.front;
					}
					ret = ret/dt.length;
				}
				else{
					return last.value;
				}
			}
			return ret;

		}

		/**
			Returns the time-weighted average of values stored in data for a specified time in milliseconds
		*/
		T TimedAvgOnDuration(T)(ref Fifo!(TimestampedValue!T) data, TickDuration dur){
			T ret = GetZero!T();

			auto rng = data.elements.opSlice();
			if(rng.empty)
				return ret;

			TickDuration now = Clock.currAppTick();

			TickDuration prevdate=now;
			
			while(!rng.empty && (now-rng.front.time)<=dur){

				ret += rng.front.value * (prevdate-rng.front.time).length;

				//Update values
				prevdate = rng.front.time;
				rng.popFront();
			}

			TickDuration totalduration;

			//Calculation on the total duration = dur
			if(!rng.empty){
				totalduration = dur;
				TickDuration notcalculatedtime = dur - (now-prevdate);
				ret += rng.front.value * notcalculatedtime.length;

			}
			//Calculation on the elements duration
			else{
				totalduration = now - prevdate;
			}

			return ret / totalduration.length;
		}

		/**
			Executes a kalman filter on the stored values
		*/
		T Kalman(T)(ref Fifo!(TimestampedValue!T) data){

			//TODO : implement this !

			return Raw!T(data);
		}

	}

	private static{

		T GetZero(T)(){
			import gpscoord;
			static if(is(T : float) || is(T : double))
				return 0.0;
			else static if(is(T : cfloat))
				return 0.0+0.0i;
			else static if(is(T : GpsCoord))
				return GpsCoord(0.0, 0.0);
			else
				return 0;
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

	auto now = Clock.currAppTick();
	list = DList!Tsvf([
		Tsvf(now-TickDuration.from!"msecs"(50), 20),
		Tsvf(now-TickDuration.from!"msecs"(70), 15),
		Tsvf(now-TickDuration.from!"msecs"(90), 5),
		Tsvf(now-TickDuration.from!"msecs"(100), 10)
			]);
	fifo = Fifo!(Tsvf)(4, list);
	assert(std.math.abs(Filter.TimedAvgOnDuration!float(fifo, TickDuration.from!"msecs"(100)) - 15.0)<0.1);
	assert(std.math.abs(Filter.TimedAvgOnDuration!float(fifo, TickDuration.from!"msecs"(70)) - 18.57)<0.1);
	assert(std.math.abs(Filter.TimedAvgOnDuration!float(fifo, TickDuration.from!"msecs"(80)) - 16.87)<0.1);

	SailLog.Notify("Filter unittest done");
}