#ifndef _IMAGE_WRITER_H_
#define _IMAGE_WRITER_H_

#include "cstdint"

#include "CImg.h"
#include "bluesy.h"

using namespace cimg_library;

class ImageWriter {
public:

    static bool mem_to_file_seq(bluesy::ptr_type ram_ptr, uint32_t width, uint32_t height, const char* filename, uint64_t start_addr = 0x0);

    static bool mem_to_file_gray(bluesy::ptr_type ram_ptr, uint32_t width, uint32_t height, const char* filename, uint64_t start_addr = 0x0);

    static bool mem_to_file_interleaved(bluesy::ptr_type ram_ptr, uint32_t width, uint32_t height, const char* filename, uint64_t start_addr = 0x0);

    static bool mem_to_file_gray_packed(bluesy::ptr_type ram_ptr, uint32_t width, uint32_t height, const char* filename, uint64_t start_addr = 0x0);

};

class ImageWriterStream {
public:

    ImageWriterStream(const char* filename, uint32_t width, uint32_t height);
    ~ImageWriterStream();

    void put_r(uint8_t pixel, bool incr = false);
    void put_g(uint8_t pixel, bool incr = false);
    void put_b(uint8_t pixel, bool incr = true);

private:
    void check_bounds();

    CImg<uint8_t> m_img;
    uint32_t m_pixels;
    uint32_t m_current_pixel;
    std::string m_filename;
};

#endif //_IMAGE_WRITER_H_