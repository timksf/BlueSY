# ex00

To build just got to `ex00/bsv` and type `make sim NAME=TestAXI4DummyRAM`. This will read a test image 
into the dummy RAM and then use an AXI adapter to read the image and write it to another location in the RAM before writing the resulting image to a file.