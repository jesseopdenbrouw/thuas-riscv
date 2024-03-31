/*
 *
 * upload.c - upload an S-record file to the THUAS RISC-V
 *            processor in the Cyclone V FPGA
 *
 * (c) 2024, Jesse E. J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
 *
 * Usage: upload -vnqrB -d <device> -b <baud> -t <timeout> -s <sleep> filename
 *        -v           -- verbose
 *        -B           -- send BREAK before transmitting
 *        -n           -- don't wait for response
 *        -q           -- quiet, only errors
 *        -r           -- run application after upload
 *        -d <device>  -- serial device
 *        -b <baud>    -- set baudrate
 *        -t <timeout> -- timeout in deci seconds
 *        -s <sleep>   -- sleep milli seconds after each character
 */

/* We need stdio.h anyway */
#include <stdio.h>

/* Version */
#define VERSION "0.3.1"

/* Test for Visual Studio */
#if defined(_MSC_VER)

#pragma warning(disable : 4996)
#include <windows.h>
#include "getopt.h"
#define B9600 CBR_9600
#define B115200 CBR_115200
#define B230400 (230400)
typedef DWORD speed_t;
typedef HANDLE DEVICE_HANDLE;
#define DEFAULT_SERIAL_DEVICE "COM1"

/* Test for GCC for Windows*/
#elif defined(WIN32) || defined(WIN64) || defined (WINNT)

#include <windows.h>
#include <getopt.h>
#define B9600 CBR_9600
#define B115200 CBR_115200
#define B230400 (230400)
typedef DWORD speed_t;
typedef HANDLE DEVICE_HANDLE;
#define DEFAULT_SERIAL_DEVICE "COM1"

/* Probably Linux */
#else

#include <errno.h>
#include <fcntl.h> 
#include <string.h>
#include <termios.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdbool.h>

typedef int DEVICE_HANDLE;
typedef _Bool BOOL;
typedef int DWORD;
#define INVALID_HANDLE_VALUE (-1)
#define DEFAULT_SERIAL_DEVICE "/dev/ttyUSB0"

#endif

/* Visual Studio and GCC on Windows */
#if defined(_MSC_VER) || defined(WIN32) || defined(WIN64) || defined (WINNT)

DEVICE_HANDLE open_device(char *portname) {

    char comPortName[100];

    snprintf(comPortName, sizeof comPortName, "\\\\.\\%s", portname);
    return CreateFileA(comPortName, GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL);
}

BOOL set_com_params(DEVICE_HANDLE device, DWORD speed, DWORD timeout) {

    DCB dcb;
    BOOL ret;
    COMMTIMEOUTS timeouts = { 0 };

    ret = GetCommState(device, &dcb);

    if (!ret) {
        return FALSE;
    }

    dcb.fParity = FALSE;
    dcb.BaudRate = speed;
    dcb.ByteSize = 8;
    dcb.Parity = NOPARITY;
    dcb.StopBits = ONESTOPBIT;
    dcb.fOutxCtsFlow = FALSE;
    dcb.fOutxDsrFlow = FALSE;
    dcb.fDtrControl = DTR_CONTROL_DISABLE;
    dcb.fDsrSensitivity = FALSE;
    dcb.fOutX = FALSE;
    dcb.fInX = FALSE;
    dcb.fRtsControl = RTS_CONTROL_DISABLE;

    ret = SetCommState(device, &dcb);

    if (!ret) {
        return FALSE;
    }

    timeouts.ReadIntervalTimeout = 0;
    timeouts.ReadTotalTimeoutConstant = timeout * 100;
    timeouts.ReadTotalTimeoutMultiplier = 0;
    timeouts.WriteTotalTimeoutConstant = timeout * 100;
    timeouts.WriteTotalTimeoutMultiplier = 0;

    if (!SetCommTimeouts(device, &timeouts)) {
        return FALSE;
    }

    return TRUE;
}

int read_device(DEVICE_HANDLE device, char *str, DWORD len) {

    DWORD nBytesRead;

    ReadFile(device, str, len, &nBytesRead, NULL);

    return nBytesRead;
}

int write_device(DEVICE_HANDLE device, char *str, DWORD len) {

    DWORD nBytesWritten;

    WriteFile(device, str, len, &nBytesWritten, NULL);

    return nBytesWritten;
}

void close_device(DEVICE_HANDLE device) {

    CloseHandle(device);
}

int send_break_to_device(DEVICE_HANDLE device) {
    SetCommBreak(device);
    Sleep(270);
    ClearCommBreak(device);

    return 1;
}

/* Probably Linux */
#else

DEVICE_HANDLE open_device(char *portname) {

    int fd = open(portname, O_RDWR | O_NOCTTY | O_SYNC);

    if (fd < 0) {
        return INVALID_HANDLE_VALUE;
    }
    return fd;
}

/* Com port settings on Linux */
int set_blocking(int fd, int should_block, int timeout)
{
    struct termios tty;

    memset(&tty, 0, sizeof tty);

    if (tcgetattr(fd, &tty) != 0) {
        printf("error %d from tcgetattr\n", errno);
        return 1;
    }

    tty.c_cc[VMIN]  = should_block ? 1 : 0;
    tty.c_cc[VTIME] = timeout;

    if (tcsetattr(fd, TCSANOW, &tty) != 0) {
        printf("error %d setting term attributes\n", errno);
        return 1;
    }

    return 0;
}

int set_interface_attribs(int fd, int speed, int parity)
{
    struct termios tty;

    memset (&tty, 0, sizeof tty);

    if (tcgetattr(fd, &tty) != 0) {
        printf("error %d from tcgetattr\n", errno);
        return 1;
    }

    cfsetospeed(&tty, speed);
    cfsetispeed(&tty, speed);

    tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8;     // 8-bit chars
    // disable IGNBRK for mismatched speed tests; otherwise receive break
    // as \000 chars
    tty.c_iflag &= ~IGNBRK;         // disable break processing
    tty.c_lflag = 0;                // no signaling chars, no echo,
                                        // no canonical processing
    tty.c_oflag = 0;                // no remapping, no delays
    tty.c_cc[VMIN]  = 0;            // read doesn't block
    tty.c_cc[VTIME] = 5;            // 0.5 seconds read timeout

    tty.c_iflag &= ~(IXON | IXOFF | IXANY); // shut off xon/xoff ctrl

    tty.c_cflag |= (CLOCAL | CREAD);// ignore modem controls,
                                        // enable reading
    tty.c_cflag &= ~(PARENB | PARODD);      // shut off parity
    tty.c_cflag |= parity;
    tty.c_cflag &= ~CSTOPB;
    tty.c_cflag &= ~CRTSCTS;

    if (tcsetattr(fd, TCSANOW, &tty) != 0) {
        printf("error %d from tcsetattr\n", errno);
        return 1;
    }

    return 0;
}


BOOL set_com_params(DEVICE_HANDLE device, DWORD speed, DWORD timeout) {

    set_interface_attribs(device, speed, 0);
    set_blocking(device, 0, timeout);
    return true;
}

int read_device(DEVICE_HANDLE device, char *str, DWORD len) {

    return read(device, str, len);
}

int write_device(DEVICE_HANDLE device, char *str, DWORD len) {

    return write(device, str, len);
}

void close_device(DEVICE_HANDLE device) {

    close(device);
}

int send_break_to_device(DEVICE_HANDLE device) {

    return tcsendbreak(device, 0) < 0 ? 0 : 1;
}

void Sleep(int tim) {

    usleep(tim * 1000);
}

#endif

/* The main program */
int main(int argc, char *argv[]) {

    /* The serial port, USB-to-serial first device in Linux, COMx port in Windows */
    char* portname = DEFAULT_SERIAL_DEVICE;
    /* Transmit speed */
    speed_t baudrate = B115200;
    /* Buffer... */
    char line[1000] = { 0 };
    /* Number of chars read in via port */
    int n;

    /* Input file */
    FILE *fin = NULL;
    /* Device file descriptor */
    DEVICE_HANDLE device;
    int linenr = 0;

    /* Options */
    int opt;
    int verbose = 0;
    int timeout = 10;
    int jump = 0;
    int slepe = 0;
    int quiet = 0;
    int nowait = 0;
    int sendbreak = 0;

    /* Check for 0 extra arguments */
    if (argc == 1) {
        printf("upload -vnqrB -d <device> -b <baud> -t <timeout> -s <sleep> filename\n");
        printf("Upload S-record file to THUAS RISC-V processor v" VERSION "\n");
        printf("-v           -- verbose\n");
        printf("-B           -- send BREAK before transmitting\n");
        printf("-n           -- don't wait for reponse from bootloader\n");
        printf("                (bootloader is instructed not to send response)\n");
        printf("-q           -- quiet, only errors\n");
        printf("-r           -- run application after upload\n");
        printf("-d <device>  -- serial device\n");
        printf("-b <baud>    -- set baudrate (9600, 115200 or 230400)\n");
        printf("-t <timeout> -- timeout in deci seconds\n");
        printf("-s <sleep>   -- sleep milli seconds after each character\n");
        printf("filename is a S-record file\n");
        printf("Default device is %s\n", portname);
        printf("Default baudrate is ");
        if (baudrate == B9600) {
            printf("9600\n");
        }
        else if (baudrate == B115200) {
            printf("115200\n");
        }
        else if (baudrate == B230400) {
            printf("230400\n");
        }
        else {
            printf("??\n");
        }
        printf("Default timeout is %d\n", timeout);
        printf("Default sleep is %d\n", slepe);
        exit(EXIT_SUCCESS);
    }

    /* Parse options */
    while ((opt = getopt(argc, argv, "vd:t:rjs:qb:inB")) != -1) {
        switch (opt) {
        case 'd':
            portname = optarg;
            break;
        case 'j': /* deprecated */
        case 'r':
            jump = 1;
            break;
        case 'v':
            verbose = 1;
        case 'q':
            quiet = 1;
            break;
        case 'B':
            sendbreak = 1;
            break;
        case 't':
            timeout = atoi(optarg);
            if (timeout < 0) {
                timeout = 0;
            }
            break;
        case 's':
            slepe = atoi(optarg);
            if (slepe < 0) {
                slepe = 0;
            }
            break;
        case 'b':
            if (strcmp(optarg, "9600") == 0) {
                baudrate = B9600;
            }
            else if (strcmp(optarg, "115200") == 0) {
                baudrate = B115200;
            }
            else if (strcmp(optarg, "230400") == 0) {
                baudrate = B230400;
            }
            else {
                baudrate = B9600;
            }
            break;
        case 'n':
            nowait = 1;
            break;
        default: /* '?' */
            //fprintf(stderr, "Unknown option '%c'\n", opt);
            exit(1);
        }
    }

    /* No S-record input filename */
    if (optind >= argc) {
        fprintf(stderr, "Please supply an input filename\n");
        exit(2);
    }

    /* Open the S-record file */
    fin = fopen(argv[optind], "r");
    if (fin == NULL) {
        fprintf(stderr, "Cannot open input file %s\n", argv[optind]);
        exit(3);
    }

    /* Print serial port name */
    if (verbose) {
        printf("Serial port is: %s\n", portname);
    }

    /* Open serial device */
    device = open_device(portname);

    /* Device cannot be opened */
    if (device == INVALID_HANDLE_VALUE) {
        printf("Error opening device %s\n", portname);
        fclose(fin);
        exit(4);
    }

    /* Set communication parameters */
    if (!set_com_params(device, baudrate, timeout)) {
        printf("Cannot set interface parameters!\n");
        close_device(device);
        fclose(fin);
        exit(5);
    }

    /* Zero out the buffer */
    memset(line, 0, sizeof line);

    /* Do we need to send a BREAK condition? */
    if (sendbreak) {
        if (verbose) {
            printf("Sending BREAK\n");
        }
        if (!send_break_to_device(device)) {
            printf("Cannot send BREAK to device!\n");
            close_device(device);
            fclose(fin);
            exit(6);
        }
       Sleep(500);
    }

    /* Write the ! or $ to start uploading */
    if (verbose) {
        if (nowait) {
            printf("Sending '$'... ");
        }
        else {
            printf("Sending '!'... ");
        }
        fflush(stdout);
    }
    if (nowait) {
        n = write_device(device, "$", 1);
    }
    else {
        n = write_device(device, "!", 1);
    }

    /* If we wait for a reply from the bootloader... */
    if (!nowait) {

        /* Read in data from device */
        n = read_device(device, line, 1);

        /* Did we receive */
        if (n == 0) {
            printf("Cannot contact bootloader!\n");
            printf("Did you closed the terminal program?\n");
            fflush(stdout);
            close_device(device);
            fclose(fin);
            exit(6);
        }

        if (verbose) {
            printf("Contacted bootloader!\n");
            fflush(stdout);
        }
    }

    /* Read in data from device, if any */
    n = read_device(device, line, 5);

    /* Write the data to the bootloader */
    while (fgets(line, sizeof line - 2, fin)) {
        linenr++;
        if (verbose) {
            printf("Write ");
            fflush(stdout);
        }
        /* Send data one character at a time */
        for (int i = 0; i < strlen(line); i++) {
            n = write_device(device, line + i, 1);
            if (verbose) {
                if (line[i] != '\n' && line[i] != '\r') {
                    printf("%c", line[i]);
                }
            }
            fflush(stdout);
            Sleep(slepe);
        }
        memset(line, 0, sizeof line);

        if (!nowait) {
            /* Read in data from device */
            while (1) {
                n = read_device(device, line, 1);
                if (n == 0) {
                    break;
                }
                if (line[0] == '\n') {
                    break;
                }
            }
            if (n == 0) {
                printf("Nothing read while sending data!\n");
                printf("Did you closed the terminal program?\n");
                fflush(stdout);
                close_device(device);
                fclose(fin);
                exit(8);
            }
            else {
                if (verbose) {
                    printf("  OK\n");
                    fflush(stdout);
                }
                else if (!quiet) {
                    printf("*");
                    fflush(stdout);
                }
            }
        }
        else {
            if (verbose) {
                printf("  OK\n");
                fflush(stdout);
            }
            else if (!quiet) {
                printf("*");
                fflush(stdout);
            }
        }
    }

    if (!quiet && !verbose) {
        printf("\n");
        fflush(stdout);
    }

    /* Write end of transmission marker */
    if (jump) {
        /* Start application */
        if (verbose) {
            printf("Write 'J' ");
            fflush(stdout);
        }
        n = write_device(device, "J", 1);
    }
    else {
        /* Break to bootloader monitor */
        if (verbose) {
            printf("Write '#' ");
            fflush(stdout);
        }
        n = write_device(device, "#", 1);
    }

    if (!nowait) {
        /* Read in data from device */
        while (1) {
            n = read_device(device, line, 1);
            if (n == 0) {
                break;
            }
            if (line[0] == '\n') {
                break;
            }
        }
        if (n == 0) {
            printf("Nothing read while sending end of transmission!\n");
            printf("Did you closed the terminal program?\n");
            fflush(stdout);
            close_device(device);
            fclose(fin);
            exit(9);
        }
        else {
            if (verbose) {
                printf("  OK\n");
                fflush(stdout);
            }
        }
    }
    else {
        if (verbose) {
            printf("  OK\n");
            fflush(stdout);
        }
    }

    /* Close the device and file */
    close_device(device);
    fclose(fin);

}
