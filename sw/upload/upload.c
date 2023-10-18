/*
 *
 * upload.c - upload an S-record file to the THUAS RISC-V
 *            processor in the Cyclone V FPGA
 *
 * (c) 2023, Jesse E. J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
 *
 * Usage: upload -v -d <device> -t <timeout> filename
 *        -v           -- verbose
 *        -n           -- don't wait for response
 *        -q           -- quiet, only errors
 *        -j           -- run application after upload
 *        -d <device>  -- serial device
 *        -b <baud>    -- set baudrate
 *        -t <timeout> -- timeout in deci seconds
 *        -s <sleep>   -- sleep micro seconds after each character
 */

#include <stdio.h>
#include <errno.h>
#include <fcntl.h> 
#include <string.h>
#include <termios.h>
#include <unistd.h>
#include <stdlib.h>

#define VERSION "0.1"

int set_interface_attribs(int fd, int speed, int parity)
{
	struct termios tty;

	memset (&tty, 0, sizeof tty);

	if (tcgetattr(fd, &tty) != 0) {
	        printf("error %d from tcgetattr\n", errno);
	        return -1;
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
		return -2;
	}

	return 0;
}

int set_blocking(int fd, int should_block, int timeout)
{
	struct termios tty;

	memset(&tty, 0, sizeof tty);

	if (tcgetattr(fd, &tty) != 0) {
		printf("error %d from tcgetattr\n", errno);
		return -3;
	}

	tty.c_cc[VMIN]  = should_block ? 1 : 0;
	tty.c_cc[VTIME] = timeout;

	if (tcsetattr(fd, TCSANOW, &tty) != 0) {
		printf("error %d setting term attributes\n", errno);
		return -4;
	}

	return 0;
}

int main(int argc, char *argv[]) {

	/* The serial port, USB-to-serial first device in Linux */	
	char *portname = "/dev/ttyUSB0";
	/* Transmit speed */
	speed_t baudrate = B115200;
	/* Buffer... */
	char line[1000] = { 0 };
	/* Number of chars read in via port */
	int n;

	/* Input file */
	FILE *fin = NULL;
	/* Device file descriptor */
	int fd = 0;
	int linenr = 0;

	/* Options */
	int opt;
	int verbose = 0;
	int timeout = 10;
	int jump = 0;
	int slepe = 0;
	int quiet = 0;
	int nowait = 0;

	/* Check for 0 extra arguments */
	if (argc == 1) {
		printf("upload -vnqj -d <device> -b <baud> -t <timeout> -s <sleep> filename\n");
		printf("Upload S-record file to THUAS RISC-V processor v" VERSION "\n");
		printf("-v           -- verbose\n");
		printf("-n           -- don't wait for reponse from bootloader\n");
		printf("                (bootloader is instructed not to send response)\n");
		printf("-q           -- quiet, only errors\n");
		printf("-j           -- run application after upload\n");
		printf("-d <device>  -- serial device\n");
		printf("-b <baud>    -- set baudrate (9600, 115200 or 230400)\n");
		printf("-t <timeout> -- timeout in deci seconds\n");
		printf("-s <sleep>   -- sleep micro seconds after each character\n");
		printf("Default device is %s\n", portname);
		printf("Default baudrate is ");
		if (baudrate == B9600) {
			printf("9600\n");
		} else if (baudrate == B115200) {
			printf("115200\n");
		} else if (baudrate == B230400) {
			printf("230400\n");
		} else {
			printf("??\n");
		}
		printf("Default timeout is %d\n", timeout);
		printf("Default sleep is %d\n", slepe);
		exit(EXIT_SUCCESS);
	}

	/* Parse options */
	while ((opt = getopt(argc, argv, "vd:t:js:qb:in")) != -1) {
		switch (opt) {
		case 'd':
			portname = optarg;
			break;
		case 'j':
			jump = 1;
			break;
		case 'v':
			verbose = 1;
		case 'q':
			quiet = 1;
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
		    } else if (strcmp(optarg, "115200") == 0) {
			    baudrate = B115200;
		    } else if (strcmp(optarg, "230400") == 0) {
			    baudrate = B230400;
		    } else {
			    baudrate = B9600;
		    }
		    break;
		case 'n':
			nowait = 1;
			break;
		default: /* '?' */
		    fprintf(stderr, "Unknown option '%c'\n", opt);
	            exit(-5);
	        }
	}

	if (optind >= argc) {
	    fprintf(stderr, "Please supply an input filename\n");
	    exit(-6);
	}

	fin = fopen(argv[optind], "r");
	if (fin == NULL) {
		fprintf(stderr, "Cannot open input file %s\n", argv[optind]);
		exit(-7);
	}

	if (verbose) {
		printf("Serial port is: %s\n", portname);
	}

	/* Open the device */	
	fd = open(portname, O_RDWR | O_NOCTTY | O_SYNC);

	/* Check if device is open */
	if (fd < 0) {
		printf("error %d opening %s: %s\n", errno, portname, strerror (errno));
		fclose(fin);
		exit(-8);
	}

	/* Set transmission parameters */
	set_interface_attribs(fd, baudrate, 0);
	/* Set non-blocking */
	set_blocking(fd, 0, timeout);

	/* Zero out the buffer */
	memset(line, 0, sizeof line);

	/* Write the ! to start uploading */
	if (verbose) {
		if (nowait) {
			printf("Sending '$'... ");
		} else {
			printf("Sending '!'... ");
		}
		fflush(stdout);
	}
	if (nowait) {
		n = write(fd, "$", 1);
	} else {
		n = write(fd, "!", 1);
	}

	/* If we wait for a reply from the bootloader... */
	if (!nowait) {

		/* Read in data from device */
		n = read(fd, line, 1);

		/* Did we receive */
		if (n == 0) {
			printf("Cannot contact bootloader!\n");
			printf("Did you closed the terminal program?\n");
			fflush(stdout);
			close(fd);
			fclose(fin);
			exit(-9);
		}

		if (verbose) {
			printf("Contacted bootloader!\n");
			fflush(stdout);
		}
	}

	/* Read in data from device, if any */
	n = read(fd, line, 5);

	/* Write the data to the bootloader */
	while (fgets(line, sizeof line - 2, fin)) {
		linenr++;
		if (verbose) {
			printf("Write ");
			fflush(stdout);
		}
		/* Send data one character at a time */
		for (int i=0; i < strlen(line); i++) {
			n = write(fd, line+i, 1);
			if (verbose) {
				if (line[i] != '\n' && line[i] != '\r') {
					printf("%c", line[i]);
				}
			}
			fflush(stdout);
			usleep(slepe);
		}
		memset(line, 0, sizeof line);

		if (!nowait) {
			/* Read in data from device */
			while (1) {
				n = read(fd, line, 1);
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
				close(fd);
				fclose(fin);
				exit(-11);
			} else {
				if (verbose) {
					printf("  OK\n");
					fflush(stdout);
				} else if (!quiet) {
					printf("*");
					fflush(stdout);
				}
			}
		} else {
			if (verbose) {
				printf("  OK\n");
				fflush(stdout);
			} else if (!quiet) {
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
		n = write(fd, "J", 1);
	} else {
		/* Break to bootloader monitor */
		if (verbose) {
			printf("Write '#' ");
			fflush(stdout);
		}
		n = write(fd, "#", 1);
	}

	if (!nowait) {
		/* Read in data from device */
		while (1) {
			n = read(fd, line, 1);
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
			close(fd);
			fclose(fin);
			exit(-12);
		} else {
			if (verbose) {
				printf("  OK\n");
				fflush(stdout);
			}
		}
	} else {
		if (verbose) {
			printf("  OK\n");
			fflush(stdout);
		}
	}

	/* Close devices */
	close(fd);
	fclose(fin);
}
