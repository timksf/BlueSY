
#include <iostream>
#include <cstdint>

#include "image_display.h"

void ImageDisplay::display(const char* filename) {
    cimg_library::CImg<uint8_t> image(filename);
    image.display();
}

BSV_WRAP_CLASS_METHOD(ImageDisplay, display, void, (const char*, filename))