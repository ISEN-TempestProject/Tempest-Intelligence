module fifo;

import std.container;

/**
	Basic fifo class
*/
struct Fifo(T) {
	this(size_t size) {
		m_nMaxSize = size;
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