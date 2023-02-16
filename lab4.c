/*
 * "Hello World" example.
 *
 * This example prints 'Hello from Nios II' to the STDOUT stream. It runs on
 * the Nios II 'standard', 'full_featured', 'fast', and 'low_cost' example
 * designs. It runs with or without the MicroC/OS-II RTOS and requires a STDOUT
 * device in your system's hardware.
 * The memory footprint of this hosted application is ~69 kbytes by default
 * using the standard reference design.
 *
 * For a reduced footprint version of this template, and an explanation of how
 * to reduce the memory footprint for a given application, see the
 * "small_hello_world" template.
 *
 */

#include <stdio.h>
#include <inttypes.h>
#include "system.h"
#include "io.h"
#include <unistd.h>

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#include "demo_code/i2c/i2c.h"

#define I2C_FREQ              (50000000) /* 10 MHz -- clock frequency driving the i2c core: 10 MHz in this example (ADAPT TO YOUR DESIGN) */
#define TRDB_D5M_I2C_ADDRESS  (0xba)

#define TRDB_D5M_0_I2C_0_BASE (I2C_0_BASE)   /* take i2c base address from system.h (ADAPT TO YOUR DESIGN) */

bool trdb_d5m_write(i2c_dev *i2c, uint8_t register_offset, uint16_t data) {
    uint8_t byte_data[2] = {(data >> 8) & 0xff, data & 0xff};

    int success = i2c_write_array(i2c, TRDB_D5M_I2C_ADDRESS, register_offset, byte_data, sizeof(byte_data));

    if (success != I2C_SUCCESS) {
        return false;
    } else {
        return true;
    }
}

bool trdb_d5m_read(i2c_dev *i2c, uint8_t register_offset, uint16_t *data) {
    uint8_t byte_data[2] = {0, 0};

    int success = i2c_read_array(i2c, TRDB_D5M_I2C_ADDRESS, register_offset, byte_data, sizeof(byte_data));

    if (success != I2C_SUCCESS) {
        return false;
    } else {
        *data = ((uint16_t) byte_data[0] << 8) + byte_data[1];
        return true;
    }
}

#define PIXEL (2)
#define IMAGE (2 * (320) * (240))

void read_and_save(char* c) {

    FILE* file_destination = fopen(c, "wb");
    printf("starting saving \n");
    if (!file_destination) {
     printf("Error: could not open \"%s\" for writing\n", "ddd");
     return;
    }

    for (uint32_t i = 0; i < IMAGE; i += PIXEL) {

        // Reading procedure
        int16_t read_data;
        // fread(&read_data, 2, 1, file_origin);
        read_data = IORD_16DIRECT(HPS_0_BRIDGES_BASE, i);

        uint8_t color[3];
        color[0] = (uint8_t)((read_data & 0xF800) >> 8);
        color[1] = (uint8_t)((read_data & 0x07E0) >> 3);
        color[2] = (uint8_t)((read_data & 0x001F) << 3);

      //  printf("origin: %hu, converted to (%d,%d,%d)\n", read_data, color[0], color[1], color[2]);
        fwrite(color, 1, 3, file_destination);
    }
    printf("finished");
    fclose(file_destination);
  
}
int main(void) {
    i2c_dev i2c = i2c_inst((void *) TRDB_D5M_0_I2C_0_BASE);
    i2c_init(&i2c, I2C_FREQ);

    bool success = true;
 //   read_and_save("/mnt/host/output2");
    printf("Settings up camera \n");

    // Set clock divider to 8
    success &= trdb_d5m_write(&i2c, 0x00A, 8);

    // Set row bin and row skip to 3
    success &= trdb_d5m_write(&i2c, 0x022, 0b110011);

    // Set column bin and column skip to 3
    success &= trdb_d5m_write(&i2c, 0x23, 0b110011);


    // Set Global gain to 16
    success &= trdb_d5m_write(&i2c, 0x035, 16);

    usleep(1*1000*1000);
    // image of 640x480



    //printf("%i\n", readdata ^ 0x008);HPS_0_BRIDGES_BASE
    IOWR_32DIRECT(CAMERA_CONTROLLER_0_BASE, 0*4,0);
    IOWR_32DIRECT(CAMERA_CONTROLLER_0_BASE, 1*4, 0);
    IOWR_32DIRECT(CAMERA_CONTROLLER_0_BASE, 2*4,0);
    usleep(1*1000*1000);
    // set address of sdram & cam_length & start fetching
    IOWR_32DIRECT(CAMERA_CONTROLLER_0_BASE, 0*4,HPS_0_BRIDGES_BASE);
    IOWR_32DIRECT(CAMERA_CONTROLLER_0_BASE, 1*4, (2 * (320) * (240))-4);
    IOWR_32DIRECT(CAMERA_CONTROLLER_0_BASE, 2*4,1);
   // IOWR_32DIRECT(CAMERA_CONTROLLER_0_BASE, 3*4,0);
    int cam_start = 1;
    while(cam_start == 1){
    	cam_start = IORD_32DIRECT(CAMERA_CONTROLLER_0_BASE, 2*4);
    	int cam_test = IORD_32DIRECT(CAMERA_CONTROLLER_0_BASE, 3*4);
    	printf("%i %i \n",cam_start,cam_test & 1);
    	usleep(1000);
    }
    usleep(1*1000*1000);
    read_and_save("/mnt/host/output");
    if (success) {
        return EXIT_SUCCESS;
    } else {
        return EXIT_FAILURE;
    }
}
