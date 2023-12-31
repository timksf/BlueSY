#include <iostream>
#include <cstdint>
#include <vector>

#include "bluesy.h"
#include "image_writer.h"
#include "dummy_ram.h"

bool ImageWriter::mem_to_file_seq(bluesy::ptr_type ram_ptr, uint32_t width, uint32_t height, const char* filename, uint64_t start_addr){
    CImg<uint8_t> img(width, height, 1, 3, 0); //create empty rgb image filled with 0s
    DummyRAM* ram = reinterpret_cast<DummyRAM*>(ram_ptr);
    size_t sz = 3 * width * height;
    if(sz > ram->get_size()){
        std::cout << "[ImageWriter] Requested image would not fit in ram (" << sz << "/" << ram->get_size() << 
            ")" << std::endl;
        exit(EXIT_FAILURE);
    }
    for(size_t i = 0; i < sz; i++){
        img[i] = ram->read_word(i);
    }
    img.save(filename);
    std::cout << "[ImageWriter] Wrote image (" << width << "x" << height << ")"
     << " to " << filename << std::endl;
    return true;
}

bool ImageWriter::mem_to_file_interleaved(bluesy::ptr_type ram_ptr, uint32_t width, uint32_t height, const char* filename, uint64_t start_addr){
    CImg<uint8_t> img(width, height, 1, 3, 0); //create empty rgb image filled with 0s
    DummyRAM* ram = reinterpret_cast<DummyRAM*>(ram_ptr);
    size_t sz = width * height;
    if(start_addr + sz > ram->get_size()){
        std::cout << "[ImageWriter] Requested image would not fit in ram at " << start_addr << " (" 
            << sz << "/" << ram->get_size() - start_addr << ")" << std::endl;
        exit(EXIT_FAILURE);
    }
    for(uint32_t i = 0; i < height; i++){
        for(uint32_t j = 0; j < width; j++){
            uint64_t rgb = ram->read_word(start_addr + j+(i*width));
            rgb &= 0xFFFFFFFF; //assume one rgb pixel per 64bit value in lower bits
            img(j, i, 0, 0) = (rgb >> 16) & 0xFF;
            img(j, i, 0, 1) = (rgb >> 8) & 0xFF;
            img(j, i, 0, 2) = rgb & 0xFF;
        }
    }
    img.save(filename);
    std::cout << "[ImageWriter] Wrote image (" << width << "x" << height << ")"
     << " to " << filename << std::endl;
    return true;
}

bool ImageWriter::mem_to_file_gray(bluesy::ptr_type ram_ptr, uint32_t width, uint32_t height, const char* filename, uint64_t start_addr){
    CImg<uint8_t> img(width, height, 1, 1, 0); //create empty rgb image filled with 0s
    DummyRAM* ram = reinterpret_cast<DummyRAM*>(ram_ptr);
    size_t sz = width * height;
    if(start_addr + sz > ram->get_size()){
        std::cout << "[ImageWriter] Requested image would not fit in ram at" << start_addr << " (" 
            << sz << "/" << ram->get_size() - start_addr << ")" << std::endl;
        exit(EXIT_FAILURE);
    }
    for(uint32_t i = 0; i < sz; i++){
        img[i] = ram->read_word(start_addr + i);
    }
    img.save(filename);
    std::cout << "[ImageWriter] Wrote image (" << width << "x" << height << ")"
     << " to " << filename << std::endl;
    return true;
}

bool ImageWriter::mem_to_file_gray_packed(bluesy::ptr_type ram_ptr, uint32_t width, uint32_t height, const char* filename, uint64_t start_addr){
    CImg<uint8_t> img(width, height, 1, 1, 0);
    DummyRAM* ram = reinterpret_cast<DummyRAM*>(ram_ptr);
    uint32_t size = width * height;
    uint32_t rem = size % 8;
    uint32_t words = size / 8 + (rem > 0 ? 1 : 0);
     if(start_addr + words > ram->get_size()){
        std::cout << "[ImageWriter] Requested image would not fit in ram at" << start_addr << " (" 
            << words << "/" << ram->get_size() - start_addr << ")" << std::endl;
        exit(EXIT_FAILURE);
    }
    for(unsigned int i = 0; i < words; i++){
        uint64_t word = ram->read_word(start_addr + i);
        uint64_t mask = 0xFF;
        img[i*8]    = word & mask;
        img[i*8+1]  = (word & (mask << 8)) >> 8;
        img[i*8+2]  = (word & (mask << 16)) >> 16;
        img[i*8+3]  = (word & (mask << 24)) >> 24;
        img[i*8+4]  = (word & (mask << 32)) >> 32;
        img[i*8+5]  = (word & (mask << 40)) >> 40;
        img[i*8+6]  = (word & (mask << 48)) >> 48;
        img[i*8+7]  = (word & (mask << 56)) >> 56;
    }
    img.save(filename);
    std::cout << "[ImageWriter] Wrote image (" << width << "x" << height << ")"
     << " to " << filename << std::endl;
    return true;
}

BSV_WRAP_CLASS_METHOD(
    ImageWriter, 
    mem_to_file_seq,
    bool,
    (bluesy::ptr_type, ram_ptr), (uint32_t, width), (uint32_t, height), (const char*, filename), (uint64_t, start_addr) 
);

BSV_WRAP_CLASS_METHOD(
    ImageWriter, 
    mem_to_file_gray,
    bool,
    (bluesy::ptr_type, ram_ptr), (uint32_t, width), (uint32_t, height), (const char*, filename), (uint64_t, start_addr) 
);

BSV_WRAP_CLASS_METHOD(
    ImageWriter, 
    mem_to_file_interleaved,
    bool,
    (bluesy::ptr_type, ram_ptr), (uint32_t, width), (uint32_t, height), (const char*, filename), (uint64_t, start_addr) 
)

BSV_WRAP_CLASS_METHOD(
    ImageWriter, 
    mem_to_file_gray_packed,
    bool,
    (bluesy::ptr_type, ram_ptr), (uint32_t, width), (uint32_t, height), (const char*, filename), (uint64_t, start_addr) 
)


ImageWriterStream::ImageWriterStream(const char* filename, uint32_t width, uint32_t height):
    m_img(width, height, 1, 3, 0),
    m_pixels(3 * width * height),
    m_current_pixel(0),
    m_filename(filename) {

};

ImageWriterStream::~ImageWriterStream(){
    m_img.save(m_filename.c_str());
}

void ImageWriterStream::check_bounds(){
    if(m_current_pixel >= m_pixels){
        std::cerr << "[ImageWriter] Tried to write pixel beyond bounds: " << m_current_pixel + 1 << "/" << m_pixels << std::endl;
        exit(EXIT_FAILURE);
    }
}

void ImageWriterStream::put_r(uint8_t pixel, bool incr){
    check_bounds();
    m_img[m_current_pixel] = pixel;
    if(incr) ++m_current_pixel;
}

void ImageWriterStream::put_g(uint8_t pixel, bool incr){
    check_bounds();
    m_img[m_current_pixel + (m_img.width()*m_img.height())] = pixel;
    if(incr) ++m_current_pixel;
}

void ImageWriterStream::put_b(uint8_t pixel, bool incr){
    check_bounds();
    m_img[m_current_pixel + 2 * ((m_img.width()*m_img.height()))] = pixel;
    if(incr) ++m_current_pixel;
}

BSV_ENABLE_PSEUDO_GC(ImageWriterStream)
BSV_WRAP_CONSTRUCTOR(ImageWriterStream, (const char*, filename), (uint32_t, width), (uint32_t, height))
BSV_WRAP_INSTANCE_METHOD(ImageWriterStream, put_r, void, (uint8_t, pixel), (bool, incr))
BSV_WRAP_INSTANCE_METHOD(ImageWriterStream, put_g, void, (uint8_t, pixel), (bool, incr))
BSV_WRAP_INSTANCE_METHOD(ImageWriterStream, put_b, void, (uint8_t, pixel), (bool, incr))


