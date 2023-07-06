#include <vector>
#include <iostream>
#include <cstdint>
#include <cstdlib>

#include "bluesy.h"


class DummyRAM {
public:

    using data_t = uint32_t;
    using addr_t = uint32_t;

    static constexpr uint8_t bytes_per_word = 4;

    DummyRAM(const uint32_t size);
    ~DummyRAM(){
        std::cout << "[DummyRAM] [DummyRAM]: " << m_write_accesses << " write accesses" << std::endl;
        std::cout << "[DummyRAM] [DummyRAM]: " << m_read_accesses << " read accesses" << std::endl;
    }

    data_t read_word(addr_t word_addr);
    void write_word(addr_t word_addr, data_t word);

    uint32_t get_size();

private:
    uint32_t m_size;
    std::vector<data_t> m_data;
    uint32_t m_write_accesses;
    uint32_t m_read_accesses;
};

BSV_CONSTRUCTOR_HEADER_DEF(DummyRAM, (const uint32_t, size))