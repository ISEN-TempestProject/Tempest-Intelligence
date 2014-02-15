module fifo;

import std.container;

class Fifo(T) {
	this(size_t size) {
		m_nMaxSize = size;
	}

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

	size_t GetSize() const{
		return m_nSize;
	}

	DList!T GetHandle(){
		return m_list;
	}

private:
	size_t m_nMaxSize;
	size_t m_nSize = 0;
	DList!T m_list;
}