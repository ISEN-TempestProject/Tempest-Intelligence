import std.process;
import std.stdio;
import std.conv;
import col;

class Hardware {
	this() {
		//Open Pipe
	}

	/*!
		@brief Helm Orientation
		@note 0 is the middle, -1 turn left, +1 turn right
	*/
	@property{
		void Helm(float f){
			writefln(col.fg.lightred~"Helm="~to!string(f)~col.end);
		}
		float Helm(){return 0;}
	}

	/*!
		@brief Wind Direction from the north (degrees)
		@note 0 is the north, 90 is the east
	*/
	@property{
		float WindDirectionNorth(){return 0;}
	}

	/*!
		@brief Angle between the deck and babor/tribor axis (degrees)
		@note 0 is normal state 
	*/
	@property{
		float Roll(){return 0;}
	}

	/*!
		@brief Sail tension
		@note 0 is maximum tension, 1 is the lowest
	*/
	@property{
		void SailTension(float f){writeln(col.fg.lightred~"SailTension="~to!string(f)~col.end);}
	}



private:


}