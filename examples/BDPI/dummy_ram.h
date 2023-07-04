#include <vector>
#include <iostream>
#include <cstdint>
#include <cstdlib>

#include "bluesy.h"

class DummyRAM {
public:
    DummyRAM(const uint32_t size);
    ~DummyRAM(){
        std::cout << "[DummyRAM] [DummyRAM]: " << m_write_accesses << " write accesses" << std::endl;
        std::cout << "[DummyRAM] [DummyRAM]: " << m_read_accesses << " read accesses" << std::endl;
    }

    uint32_t read_word(uint32_t word_addr);
    void write_word(uint32_t word_addr, uint32_t word);
    uint32_t get_size();

private:
    uint32_t m_size;
    std::vector<uint32_t> m_data;
    uint32_t m_write_accesses;
    uint32_t m_read_accesses;
};

BSV_CONSTRUCTOR_HEADER_DEF(DummyRAM, (const uint32_t, size))