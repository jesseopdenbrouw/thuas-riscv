/* 
 * srec2vhdl - Motorola S-record to VHDL table generator
 *
 * (c)2022, J.E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
 *
 * This program converts a file with Motorola S-records to
 * a series of VHDL table statements.
 *
 * Recognized S-records: S0, S1, S2, S3, S7, S8, S9.
 * S4, S5 and S6 are skipped.
 * The checksum is not checked.
 *
 * By default, srec2vhdl creates only the table entries
 *
 * Options:
 *      -f         Creates a full table
 *      -i <arg>   Indents the tables entries by <arg>
 *      -v         Verbose output
 *      -q         Quiet output, only errors are reported
 *      -b         Output as bytes
 *      -h         Output as half words (16 bits, Little Endian)
 *      -w         Output as words (32 bits, Little Endian)
 *
 * The address of the first record is used as an offset
 * so that the first records starts at vector element 0.
 *
 * */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <unistd.h>
#include <time.h>

#define VERSION "v0.3"

/* 1000 should be enough */
#define LEN_BUFFER (1000)

/* This should really be enough */
#define LEN_CODE (10000000)

#define BYTE (1)
#define HALFWORD (2)
#define WORD (4)

/* Make next global, otherwise it can be on the stack */
unsigned char code[LEN_CODE] = { 0 };

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
	char buffer[LEN_BUFFER];
	int line = 0;
	unsigned long int val;
	unsigned long int address = 0;
	unsigned long int byte;
	int i;
	int first = 1;
	unsigned long int offset = 0;
	//int doindent = 1;
	time_t t = time(NULL);

	/* Options */
	int indent, opt;
	int verbose, full;
	int indentarg;
	int size = BYTE;
	char unused = '-';
	int writeunused = 0;

	/* Set defaults on options */
	full = 0;
	verbose = 0;
	indent = 0;
	indentarg = 0;

	/* Check for 0 extra arguments */
	if (argc == 1) {
		printf("srec2vhdl " VERSION " -- an S-record to VHDL table converter\n");
		printf("Usage: srec2vhdl [-vqfbhw0 -i <arg>] inputfile [outputfile]\n");
		printf("   -f        Full table output\n");
		printf("   -i <arg>  Indent by <arg> spaces\n");
		printf("   -v        Verbose\n");
		printf("   -q        Quiet. Only errors are reported\n");
		printf("   -b        Byte output (default)\n");
		printf("   -h        Halfword output (16 bits, Little Endian)\n");
		printf("   -w        Word output (32 bits, Little Endian)\n");
		printf("   -0        Output unused data as 0's\n");
		printf("   -d        Output unused data as don't care\n");
		printf("If outputfile is omitted, stdout is used\n");
		printf("Program size must be less then 1 MB\n\n");
		printf("The address of the first record is used as an offset\n"
                       "so that the first record starts at vector element 0.\n");
		exit(EXIT_SUCCESS);
	}

	/* Parse options */
	while ((opt = getopt(argc, argv, "0dbhwvqfi:")) != -1) {
	        switch (opt) {
       		case 'f':
	            full = 1;
		    indent = 1;
		    indentarg = 8;
	            break;
	        case 'i':
	            indentarg = atoi(optarg);
	            indent = 1;
	            break;
	        case 'v':
	            verbose = 1;
	            break;
	        case 'b':
	            size = BYTE;
	            break;
	        case 'h':
	            size = HALFWORD;
	            break;
	        case 'w':
	            size = WORD;
	            break;
	        case 'q':
	            verbose = 0;
	        case 'd':
				writeunused = 1;
	            unused = '-';
	            break;
	        case '0':
				writeunused = 1;
	            unused = '0';
	            break;
	        default: /* '?' */
		    fprintf(stderr, "Unknown option '%c'\n", opt);
	            exit(EXIT_FAILURE);
	        }
	}

	if (verbose) {
		fprintf(stderr, "srec2vhdl " VERSION " \n");
		fprintf(stderr, "S-record to VHDL converter\n");
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
			fprintf(stderr, "Using stdout\n");
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
		fprintf(fout, "-- srec2vhdl table generator\n");
		fprintf(fout, "-- for input file '%s'\n", argv[optind]);
		fprintf(fout, "-- date: %s\n\n", ctime(&t));
		fprintf(fout, "library ieee;\n");
		fprintf(fout, "use ieee.std_logic_1164.all;\n\n");
		fprintf(fout, "library work;\n");
		fprintf(fout, "use work.processor_common.all;\n\n");
		fprintf(fout, "package rom_image is\n");
		fprintf(fout, "    constant rom_contents : memory_type := (\n");
	}

	while (fgets(buffer, LEN_BUFFER, fp) != NULL) {
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
				  if (first) {
					  offset = address;
					  if (verbose) {
					  	  fprintf(stderr, "Offset: 0x%08lx\n", offset);
					  }
					  first = 0;
				  }
				  for (i = 0; i < val; i++) {
					byte = hex2(buffer+8+i*2);
					code[address-offset] = byte;
					address++;
				  }
				  break;
			case '2': val = hex2(buffer+2);
				  val = val-4;
				  address = hex6(buffer+4);
				  if (first) {
					  offset = address;
					  if (verbose) {
					  	  fprintf(stderr, "Offset: 0x%08lx\n", offset);
					  }
					  first = 0;
				  }
				  for (i = 0; i < val; i++) {
					byte = hex2(buffer+10+i*2);
					code[address-offset] = byte;
					address++;
				  }
				  break;
			case '3': val = hex2(buffer+2);
				  val = val-5;
				  address = hex8(buffer+4);
				  if (first) {
					  offset = address;
					  if (verbose) {
					  	  fprintf(stderr, "Offset: 0x%08lx\n", offset);
					  }
					  first = 0;
				  }
				  for (i = 0; i < val; i++) {
					byte = hex2(buffer+12+i*2);
					code[address-offset] = byte;
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

	/* Shift to length of data in array */
	address -= offset;

	if (address > LEN_CODE) {
		fprintf(stderr, "Warning: internal buffer too small, not exporting all data!\n");
		address = LEN_CODE;
	}

	for (i = 0; i < address; i = i + size) {
		if (indent) {
			for (int i = 0; i < indentarg; i++) {
				fprintf(fout, " ");
			}
		}
		if (size == BYTE) {
			fprintf(fout, "%4d => x\"%02x\"", i/size, code[i]);
		} else if (size == HALFWORD) {
			fprintf(fout, "%4d => x\"%02x%02x\"", i/size, code[i], code[i+1]);
		} else if (size == WORD) {
			fprintf(fout, "%4d => x\"%02x%02x%02x%02x\"", i/size, code[i], code[i+1], code[i+2], code[i+3]);
		} else {
			fprintf(stderr, "BUG:: size unknown\n");
		}
		if ((i != address-size) || writeunused) {
			fprintf(fout, ",");
		}
		fprintf(fout, "\n");
	}

	if (indent) {
		for (int i = 0; i < indentarg; i++) {
			fprintf(fout, " ");
		}
	}
	if (writeunused) {
		fprintf(fout, "others => (others => '%c')\n", unused);
	}
   	fprintf(fout, "    );\n");

	if (full) {
		fprintf(fout, "end package rom_image;\n");
	}

	if (verbose) {
		fprintf(stderr, "Transformed %lu bytes.\n", address);
	}

	fclose(fp);
	fclose(fout);

	return 0;
}
