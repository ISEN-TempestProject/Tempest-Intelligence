module fifo;

import std.container;

/**
	Basic fifo class
*/
struct Fifo(T) {
	/**
		Creates an empty fifo
	*/
	this(size_t capacity) {
		m_capacity = capacity;
	}

	/**
		Creates a fifo with content
	*/
	this(T[] data, size_t capacity=0) {
		this(DList!T(data), capacity>0? capacity : data.length);
	}

	/**
		Creates a fifo with content
	*/
	this(DList!T data, size_t capacity) {
		this(capacity);

		int count;
		foreach_reverse(ref cell ; data){
			m_list.insertFront(cell);
			count++;
			if(count>=m_capacity)
				break;
		}
		m_length = count;
	}

	/**
		Appends a value to the front of the fifo
	*/
	void add(T val){
		if(m_length>=m_capacity){
			m_list.removeFront();
			m_list.insertBack(val);
		}
		else{
			m_length++;
			m_list.insertBack(val);
		}
	}

	@property const nothrow{
		bool empty(){return m_list.empty;}
		size_t length(){return m_length;}
		size_t capacity(){return m_capacity;}
	}

	@property nothrow{
		T front()const {return m_list.front;}
		void front(T val){m_list.front = val;}
	}

	/**
		Returns the contained elements
	*/
	@property{
		auto ref elements(){
			return m_list[];
		}
	}

private:
	size_t m_capacity;
	size_t m_length = 0;
	DList!T m_list;
}


void main() {
	import saillog;

	Fifo!int fifo;

	fifo = Fifo!int([0,1,2,3,4,5,6,7]);
	writeln(fifo.capacity,"  ",fifo.length);
	assert(fifo.capacity==8 && fifo.length==8);
	assert(fifo.elements.equal([0,1,2,3,4,5,6,7]));

	//too long array
	fifo = Fifo!int([0,1,2,3,4,5,6,7], 5);
	assert(fifo.capacity==5 && fifo.length==5);
	assert(fifo.elements.equal([3,4,5,6,7]));
	//add elements to fifo
	fifo.add(8);
	assert(fifo.capacity==5 && fifo.length==5);
	assert(fifo.elements.equal([4,5,6,7,8]));
	fifo.add(9);
	assert(fifo.capacity==5 && fifo.length==5);
	assert(fifo.elements.equal([5,6,7,8,9]));


	fifo = Fifo!int([0,1,2], 5);
	assert(fifo.capacity==5 && fifo.length==3);
	assert(fifo.elements.equal([0,1,2]));
	fifo.add(3);
	assert(fifo.capacity==5 && fifo.length==4);
	assert(fifo.elements.equal([0,1,2,3]));
	fifo.add(4);
	assert(fifo.capacity==5 && fifo.length==5);
	assert(fifo.elements.equal([0,1,2,3,4]));
	fifo.add(5);
	assert(fifo.capacity==5 && fifo.length==5);
	assert(fifo.elements.equal([1,2,3,4,5]));


	SailLog.Notify("Fifo unittest done");
}