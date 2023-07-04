#include <vector>
#include <iostream>

#include "bluesy.h"
#include "dummy_ram.h"

#include "image_loader.h"
#include "image_writer.h"

void test_sequential(ImageLoader& loader, bluesy::ptr_type ram_ptr, uint32_t w, uint32_t h){
    loader.write_to_mem_seq(ram_ptr);
    ImageWriter::mem_to_file_seq(ram_ptr, w, h, "results/sequential.jpg");
}

void test_interleaved(ImageLoader& loader, bluesy::ptr_type ram_ptr, uint32_t w, uint32_t h){
    loader.write_to_mem_interleaved(ram_ptr);
    auto out = ImageWriter::mem_to_file_interleaved(ram_ptr, w, h, "results/interleaved.jpg");
}

int main(){

    uint32_t width = 1920;
    uint32_t height = 1080;
    uint32_t ram_capacity = width * height * 3.2;

    //work with normal C++ object for image loading
    ImageLoader my_loader("../test.jpg");
    bluesy::ptr_type ram_ptr = create_DummyRAM(ram_capacity);
    DummyRAM *my_ram = reinterpret_cast<DummyRAM*>(ram_ptr);

    test_sequential(my_loader, ram_ptr, width, height);
    test_interleaved(my_loader, ram_ptr, width, height);

    return 0;
}


