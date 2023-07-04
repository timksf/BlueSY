#include "dummy_ram.h"

DummyRAM::DummyRAM(const uint32_t size) : m_size(size), m_write_accesses(0), m_read_accesses(0) {
    // m_data.reserve(size);
    for(unsigned int i = 0; i < size; i++){
        m_data.push_back(0);
    }
}

uint32_t DummyRAM::read_word(uint32_t word_addr) {
    if(word_addr >= m_size) {
        std::cerr << "[DummyRAM] Tried to read word beyond bounds: " << word_addr  << "/" << (m_size-1) << std::endl;
        exit(1);
    }
    ++m_read_accesses;
    return m_data[word_addr];
}

void DummyRAM::write_word(uint32_t word_addr, uint32_t word) {
    if(word_addr >= m_size) {
        std::cerr << "[DummyRAM] Tried to write word beyond bounds: " << word_addr << "/" << (m_size-1) << std::endl;
        exit(1);
    }
    m_data[word_addr] = word;
    // if(word == 0)
    //     std::cout << "Addr: " << word_addr << " NULL" << std::endl;
    ++m_write_accesses;
}

uint32_t DummyRAM::get_size() {
    return m_size;
}

BSV_ENABLE_PSEUDO_GC(DummyRAM)
BSV_WRAP_CONSTRUCTOR(DummyRAM, (const uint32_t, size))
BSV_WRAP_INSTANCE_METHOD(DummyRAM, read_word, uint32_t, (uint32_t, word_addr))
BSV_WRAP_INSTANCE_METHOD(DummyRAM, write_word, void, (uint32_t, word_addr), (uint32_t, word))
