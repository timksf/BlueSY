#include <vector>
#include <iostream>
#include <cstdlib>

#include "CImg.h"

#include "bluesy.h"
#include "image_loader.h"
#include "dummy_ram.h"

using namespace cimg_library;

ImageLoader::ImageLoader(const char* filename) : m_image(filename), m_current_pixel(0) {
    std::cout << "[C++] Opened image with " << m_image.size() << " pixel values" << std::endl;
}

// Use this method for stream-like access
uint8_t ImageLoader::get_pixel() {
    if(m_current_pixel >= m_image.size()){
        std::cout << "[C++] Reading pixel out of bounds" << std::endl;
        exit(EXIT_FAILURE);
    }
    return m_image.data()[m_current_pixel++];
}

uint8_t ImageLoader::get_pixel_at(uint32_t idx) {
    if(idx >= m_image.size()){
        std::cout << "[C++] Reading pixel out of bounds at " << idx + 1 << "/" << m_image.size() << std::endl;
        exit(EXIT_FAILURE);
    }
    // std::cout << "[C++] Reading pixel at " << idx << std::endl;
    return m_image.data()[idx];
}

void ImageLoader::write_to_mem_seq(bluesy::ptr_type ram_ptr, uint64_t start_addr){
    DummyRAM* ram = (DummyRAM*) ram_ptr;
    if((ram->get_size() - start_addr) < m_image.size()){
        std::cout << "[C++] RAM can't fit image starting from address " <<
            std::hex << start_addr << std::endl;
        exit(EXIT_FAILURE);
    }
    uint64_t address = start_addr;
    for(uint32_t i = 0; i < m_image.size(); i++){
        ((DummyRAM*) ram_ptr)->write_word(address++, m_image[i]);
    }
}

void ImageLoader::write_to_mem_interleaved(bluesy::ptr_type ram_ptr, uint64_t start_addr){
    DummyRAM* ram = (DummyRAM*) ram_ptr;
    if((ram->get_size() - start_addr) < m_image.size() / 3)
        std::cout << "[C++] RAM can't fit image" << std::endl;
    uint32_t address = start_addr;
    int width = m_image.width();
    int height = m_image.height();
    for(int i = 0; i < width * height; i++){
        uint8_t r = m_image[i];
        uint8_t g = m_image[i+(width*height)];
        uint8_t b = m_image[i+2*(width*height)];
        uint32_t rgb = (r << 16) | (g << 8) | b;
        ram->write_word(address++, rgb);
    }
}

/*
    Takes pixels from 8 Bit grayscale images and packs 4 pixels into 
    single 32 Bit word.
*/
void ImageLoader::write_to_mem_gray_packed(bluesy::ptr_type ram_ptr, uint64_t start_addr){
    DummyRAM* ram = (DummyRAM*) ram_ptr;
    uint32_t words = m_image.size() / 8;
    uint32_t rem = m_image.size() % 8;
    if((ram->get_size() - start_addr) < (words + (rem > 0 ? 1 : 0)))
        std::cerr <<  "[C++] RAM can't fit image" << std::endl;
    uint64_t address = start_addr;
    for(unsigned int i = 0; i < words; i++){
        uint64_t word = 0;
        uint64_t data = *(uint64_t*)&m_image[i*8];
        word = data;
        ram->write_word(address++, word);
    }
    //last pixels
    if(rem > 0){
        uint64_t last_word = 0;
        for(unsigned int i = 0; i < rem; i++){
            last_word |= m_image[words*8+i] << (8*i);
        }
        ram->write_word(address, last_word);
    }
}

BSV_ENABLE_PSEUDO_GC(ImageLoader)
// currently only works for one constructor
// BSV_WRAP_CONSTRUCTOR(ImageLoader)
BSV_WRAP_CONSTRUCTOR(ImageLoader, (const char*, filename))
BSV_WRAP_INSTANCE_METHOD(ImageLoader, get_pixel, uint8_t)
BSV_WRAP_INSTANCE_METHOD(
    ImageLoader,
    write_to_mem_seq,
    void,
    (bluesy::ptr_type, ram_ptr), (uint64_t, start_addr)
)

BSV_WRAP_INSTANCE_METHOD(
    ImageLoader,
    write_to_mem_interleaved,
    void,
    (bluesy::ptr_type, ram_ptr), (uint64_t, start_addr)
)

BSV_WRAP_INSTANCE_METHOD(
    ImageLoader,
    get_pixel_at,
    uint8_t,
    (uint32_t, index)
)

BSV_WRAP_INSTANCE_METHOD(
    ImageLoader,
    write_to_mem_gray_packed,
    void,
    (bluesy::ptr_type, ram_ptr), (uint64_t, start_addr)
)