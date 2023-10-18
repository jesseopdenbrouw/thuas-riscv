/* 
 * srec2mif - Motorola S-record to MIF converter
 *
 * (c)2021, J.E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
 *
 * This program converts a file with Motorola S-records to
 * a series of Memory Initialization File (mif) statements
 *
 * Recognized S-records: S0, S1, S2, S3, S7, S8, S9.
 * S4, S5 and S6 are skipped.
 * The checksum is not checked.
 *
 * Options:
 *      -v         Verbose output
 *      -q         Quiet output, only errors are reported
 *
 * */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <unistd.h>

/* 1000 should be enough */
#define LENGTH 1000

/* Convert 2 ASCII characters to 1 byte */
unsigned long int hex2(char buffer[]) {
	unsigned long int val = 0;
	unsigned long int efkes = 0;

	buffer[0] = toupper(buffer[0]);
	buffer[1] = toupper(buffer[1]);

	efkes = (buffer[0] >= 'A') ? 'A' - 10 : '0';
	val = (unsigned long int)buffer[0] - efkes;

	val = val << 4;

	efkes = (buffer[1] >= 'A') ? 'A' - 10 : '0';
	val = val + (unsigned long int)buffer[1] - efkes;

	return val;
}

/* Convert 4 ASCII characters to 2 bytes */
unsigned long int hex4(char buffer[]) {

	unsigned long int val = 0;

	val = (hex2(buffer) << 8) + hex2(buffer+2);

	return val;
}

/* Convert 6 ASCII characters to 3 bytes */
unsigned long int hex6(char buffer[]) {

	unsigned long int val = 0;

	val = (hex2(buffer) << 16) + (hex2(buffer+2) << 8) + hex2(buffer+4);

	return val;
}

/* Convert 8 ASCII characters to 4 bytes */
unsigned long int hex8(char buffer[]) {

	unsigned long int val = 0;

	val = (hex2(buffer) << 24) + (hex2(buffer+2) << 16) + (hex2(buffer+4) << 8) + hex2(buffer+6);

	return val;
}

/* main */
int main(int argc, char *argv[]) {

	FILE *fp, *fout;
	char buffer[LENGTH];
	int line = 0;
	unsigned long int val;
	unsigned long int address;
	unsigned long int byte;
	int i;

	/* Options */
	int opt;
	int verbose, full;

	/* Set defaults on options */
	full = 1;
	verbose = 0;

	/* Check for 0 extra arguments */
	if (argc == 1) {
		printf("srec2mif -- an S-record to MIF table converter\n");
		printf("Usage: srecmif [-vq] inputfile [outputfile]\n");
		printf("   -v        Verbose\n");
		printf("   -q        Quiet. Only errors are reported\n");
		printf("If outputfile is omitted, stdout is used\n");
		exit(EXIT_SUCCESS);
	}

	/* Parse options */
	while ((opt = getopt(argc, argv, "vqfi:")) != -1) {
	        switch (opt) {
	        case 'v':
	            verbose = 1;
	            break;
	        case 'q':
	            verbose = 0;
	            break;
	        default: /* '?' */
		    fprintf(stderr, "Unknown option '%c'\n", opt);
	            exit(EXIT_FAILURE);
	        }
	}

	if (verbose) {
		fprintf(stderr, "S-record to MIF converter\n");
	}

	if (optind >= argc) {
	    fprintf(stderr, "Please supply an input filename\n");
	    exit(EXIT_FAILURE);
	}

	fp = fopen(argv[optind], "r");
	if (fp == NULL) {
		fprintf(stderr, "Cannot open input file %s\n", argv[1]);
		exit (EXIT_FAILURE);
	}


	if (argv[optind+1] == NULL) {
		if (verbose) {
			printf("Using stdout\n");
		}
		fout = stdout;
	} else {
		if (strcmp(argv[optind], argv[optind+1]) == 0) {
			fprintf(stderr, "Input filename and output filename cannot be the same\n");
			fclose(fp);
			exit(EXIT_FAILURE);
		}
		fout = fopen(argv[optind+1], "w");
		if (fout == NULL) {
			fclose(fp);
			fprintf(stderr, "Cannot open output file %s\n", argv[optind+1]);
			exit(EXIT_FAILURE);
		}
	}

	if (full) {
		fprintf(fout, "WIDTH=8;\n");
		fprintf(fout, "DEPTH=16384;\n");
		fprintf(fout, "ADDRESS_RADIX=HEX;\n");
		fprintf(fout, "DATA_RADIX=HEX;\n\n");
		fprintf(fout, "CONTENT BEGIN\n\n");
	}

	while (fgets(buffer, LENGTH, fp) != NULL) {
		line++;
		if (buffer[0] != 'S') {
			fprintf(stderr, "Not an S-record in line %d!\n", line);
			continue;
		}
		val = 0;
		switch (buffer[1]) {
			case '0': val = hex2(buffer+2);
				  val = val - 3;
				  if (verbose) {
				  	fprintf(stderr, "Vendor text: ");
				  	for (i = 0; i < val; i++) {
						char c = (char) hex2(buffer+8+i*2);
						fprintf(stderr, "%c", c);
					}
				  	fprintf(stderr, "\n");
				  }
				  break;
			case '1': val = hex2(buffer+2);
				  val = val-3;
				  address = hex4(buffer+4);
				  for (i = 0; i < val; i++) {
					byte = hex2(buffer+8+i*2);
					fprintf(fout, "%4lx : %02lx;\n", address, byte);
					address++;
				  }
				  break;
			case '2': val = hex2(buffer+2);
				  val = val-4;
				  address = hex6(buffer+4);
				  for (i = 0; i < val; i++) {
					byte = hex2(buffer+10+i*2);
					fprintf(fout, "%4lx => %02lx;\n", address, byte);
					address++;
				  }
				  break;
			case '3': val = hex2(buffer+2);
				  val = val-5;
				  address = hex8(buffer+4);
				  for (i = 0; i < val; i++) {
					byte = hex2(buffer+12+i*2);
					fprintf(fout, "%4lx => %02lx;\n", address, byte);
					address++;
				  }
				  break;
			case '4': if (verbose) {
					  fprintf(stderr, "Reserved S-record\n");
				  }
				  break;
			case '5': if (verbose) {
					  fprintf(stderr, "Optional count record skipped\n");
				  }
				  break;
			case '6': if (verbose) {
					  fprintf(stderr, "Optional count record skipped\n");
				  }
				  break;
			case '7': if (verbose) {
					  fprintf(stderr, "Termination record\n");
				  }
				  break;
			case '8': if (verbose) {
					  fprintf(stderr, "Termination record\n");
				  }
				  break;
			case '9': if (verbose) {
					  fprintf(stderr, "Termination record\n");
				  }
				  break;
			default : if (verbose) {
					  fprintf(stderr, "Invalid S-record in line %d\n", line);
				  }
				  break;
		}

	}

	if (full) {
		fprintf(fout, "\nEND;\n");
	}

	fclose(fp);
	fclose(fout);

	return 0;
}
