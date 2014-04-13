module fifo;

import std.container;

/**
	Basic fifo class
*/
struct Fifo(T) {
	this(size_t size) {
		m_nMaxSize = size;
	}
	this(size_t size, ref DList!T list) {
		m_nMaxSize = size;

		int nCount;
		foreach(ref cell ; list){
			m_list.insertBack(cell);
			nCount++;
			if(nCount>=m_nMaxSize)
				break;
		}
		m_nSize = nCount;
	}

	/**
		Appends a value to the front of the fifo
	*/
	void Append(T val){
		if(m_nSize>=m_nMaxSize){
			m_list.removeBack();
			m_list.insertFront(val);
		}
		else{
			m_list.insertFront(val);
			m_nSize++;
		}
	}

	@property const nothrow{
		bool empty(){return m_list.empty;}
		size_t length(){return m_nSize;}
	}

	@property nothrow{
		T front(){return m_list.front;}
		void front(T val){m_list.front = val;}
	}

	/**
		Returns the contained elements
	*/
	@property{
		ref DList!T elements(){
			return m_list;
		}
	}

private:
	size_t m_nMaxSize;
	size_t m_nSize = 0;
	DList!T m_list;
}


unittest {
	import saillog;
	int GetSize(T)(ref DList!T list){
		int i=0;
		foreach(ref cell ; list) i++;
		return i;
	}
	auto array = [0, 1, 2, 3, 4, 5, 6, 7];
	auto complete = DList!int(array);
	auto fifo = Fifo!int(5, complete);
	assert(fifo.length==5 && GetSize!int(fifo.elements)==5);

	SailLog.Notify("Fifo unittest done");
}