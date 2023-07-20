#ifndef _IMAGE_LOADER_H_
#define _IMAGE_LOADER_H_

#include "cstdint"

#include "CImg.h"
#include "bluesy.h"

using namespace cimg_library;

class ImageLoader {
public:

    ImageLoader(const char* filename);

    uint8_t get_pixel();

    uint8_t get_pixel_at(uint32_t index);

    //writes each value it gets from data buffer to a new address in memory
    void write_to_mem_seq(bluesy::ptr_type ram_ptr, uint64_t start_addr = 0x0);

    //interleaves RGB values of pixels so that each word contains all three values for a pixel
    void write_to_mem_interleaved(bluesy::ptr_type ram_ptr, uint64_t start_addr = 0x0);

    void write_to_mem_gray_packed(bluesy::ptr_type ram_ptr, uint64_t start_addr = 0x0);

private:
    CImg<uint8_t> m_image;
    unsigned int m_current_pixel;
};

#endif //_IMAGE_LOADER_H_