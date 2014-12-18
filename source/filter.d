module filter;

import core.time;
import std.typecons;
import std.container;
import std.range;
import std.math;
import gpscoord;

public import std.datetime;
public import fifo;

alias TimestampedValue(T) = Tuple!(TickDuration,"time", T,"value");

static class Filter {

	public static{

		/**
			Returns the last value stored in the data
		*/
		T Raw(T)(ref Fifo!(TimestampedValue!T) data){
			if(data.empty)
				return GetZero!T();
			
			return data.elements.back.value;
		}

		/**
			Returns the time-weighted average of all values stored in data
		*/
		T TimedAvg(T)(ref Fifo!(TimestampedValue!T) data){
			T ret = GetZero!T();

			auto rng = data.elements;
			if(!rng.empty){
				TickDuration dt = rng.back.time-rng.front.time;
				TimestampedValue!T last = rng.back;
				rng.popBack();

				if(!rng.empty){
					for( ; !rng.empty ; rng.popBack()){
						ret = ret + (last.value*(last.time-rng.back.time).length);
						last = rng.back;
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

			auto rng = data.elements;
			if(rng.empty)
				return ret;

			TickDuration now = Clock.currAppTick();
			TickDuration prevdate=now;
			
			while(!rng.empty && (now-rng.back.time)<=dur){

				ret += rng.back.value * (prevdate-rng.back.time).length;

				//Update values
				prevdate = rng.back.time;
				rng.popBack();
			}

			TickDuration totalduration;

			//Calculation on the total duration = dur
			if(!rng.empty){
				totalduration = dur;
				TickDuration notcalculatedtime = dur - (now-prevdate);
				ret += rng.back.value * notcalculatedtime.length;

			}
			//Calculation on the elements duration
			else{
				totalduration = now - prevdate;
			}

			return ret / totalduration.length;
		}
		
		/**
            Returns the time-weighted average of priodic angle in degrees values stored in data for a specified time in milliseconds
        */
        T TimedAvgOnDurationAngle(T)(ref Fifo!(TimestampedValue!T) data, TickDuration dur){
            T ret = GetZero!T();
            T cosAvg = GetZero!T();
            T sinAvg = GetZero!T();

            auto rng = data.elements;
            if(rng.empty)
                return ret;

            TickDuration now = Clock.currAppTick();
            TickDuration prevdate=now;
            
            while(!rng.empty && (now-rng.back.time)<=dur){

                cosAvg += cos(GpsCoord.toRad(rng.back.value)) * (prevdate-rng.back.time).length;
                sinAvg += sin(GpsCoord.toRad(rng.back.value)) * (prevdate-rng.back.time).length;

                //Update values
                prevdate = rng.back.time;
                rng.popBack();
            }

            TickDuration totalduration;

            //Calculation on the total duration = dur
            if(!rng.empty){
                totalduration = dur;
                TickDuration notcalculatedtime = dur - (now-prevdate);
                cosAvg += cos(GpsCoord.toRad(rng.back.value)) * notcalculatedtime.length;
                sinAvg += sin(GpsCoord.toRad(rng.back.value)) * notcalculatedtime.length;

            }
            //Calculation on the elements duration
            else{
                totalduration = now - prevdate;
            }
            
            sinAvg /= totalduration.length;
            cosAvg /= totalduration.length;

            return GpsCoord.toDeg(atan2(sinAvg, cosAvg));
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

	bool approx(double a, double b){
		return std.math.abs(a-b)<=0.1;
	}

	auto now = Clock.currAppTick();
	auto fifo = Fifo!Tsvf(
		[
		Tsvf(now-TickDuration.from!"seconds"(90), 2), 
		Tsvf(now-TickDuration.from!"seconds"(60), 4), 
		Tsvf(now-TickDuration.from!"seconds"(30), 8), 
		Tsvf(now-TickDuration.from!"seconds"(10), 16)
		], 4);

	//Raw
	assert(Filter.Raw!float(fifo)==16);

	//TimedAvg
	assert(approx(Filter.TimedAvg!float(fifo), (16*20+8*30+4*30)/80.0));

	//TimedAvgOnDuration
	assert(approx(Filter.TimedAvgOnDuration!float(fifo, TickDuration.from!"seconds"(10)), 16));
	assert(approx(Filter.TimedAvgOnDuration!float(fifo, TickDuration.from!"seconds"(20)), 12));
	assert(approx(Filter.TimedAvgOnDuration!float(fifo, TickDuration.from!"seconds"(90)), 500/90.0));
	assert(approx(Filter.TimedAvgOnDuration!float(fifo, TickDuration.from!"seconds"(200)), 500/90.0));
	//TODO: check for durations that are not round


	auto fifoangle = Fifo!Tsvf(
		[
		Tsvf(now-TickDuration.from!"seconds"(70), 90),
		Tsvf(now-TickDuration.from!"seconds"(60), 180),
		Tsvf(now-TickDuration.from!"seconds"(50), 270+360),
		Tsvf(now-TickDuration.from!"seconds"(40), 360),
		Tsvf(now-TickDuration.from!"seconds"(20), -90),
		Tsvf(now-TickDuration.from!"seconds"(10), -180)
		]);
	assert(approx(Filter.TimedAvgOnDurationAngle!float(fifoangle, TickDuration.from!"seconds"(10)), -180));
	assert(approx(Filter.TimedAvgOnDurationAngle!float(fifoangle, TickDuration.from!"seconds"(20)), -135));
	assert(approx(Filter.TimedAvgOnDurationAngle!float(fifoangle, TickDuration.from!"seconds"(40)), -67.5));//??????????????false

	/*

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

    now = Clock.currAppTick();
    list = DList!Tsvf([
        Tsvf(now-TickDuration.from!"msecs"(50), 179),
        Tsvf(now-TickDuration.from!"msecs"(100), -179)
            ]);
    fifo = Fifo!(Tsvf)(2, list);
    SailLog.Critical("AvgAngle is : ", Filter.TimedAvgOnDurationAngle!float(fifo, TickDuration.from!"msecs"(100)) );
    assert(std.math.abs(Filter.TimedAvgOnDurationAngle!float(fifo, TickDuration.from!"msecs"(100)) - 180.0)<0.1);
    */
	SailLog.Notify("Filter unittest done");
}