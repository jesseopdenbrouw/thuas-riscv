/* 
 * srec2mif - Motorola S-record to MIF table generator
 *
 * For use with the THUAS RISC-V processor
 *
 * (c)2026, J.E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
 *
 * This program converts a file with Motorola S-records to
 * a series of MIF table statements.
 *
 * Recognized S-records: S0, S1, S2, S3, S7, S8, S9.
 * S4, S5 and S6 are skipped.
 * The checksum is not checked.
 *
 * By default, srec2mif creates only the table entries
 *
 * Options:
 *      -v         Verbose output
 *      -q         Quiet output, only errors are reported
 *      -b         Output as bytes
 *      -h         Output as half words (16 bits, Little Endian)
 *      -w         Output as words (32 bits, Little Endian)
 *      -d         Double word output (64 bits, Little Endian)\n");
 *      -r         Reverse output (half word, word and double word only)
 *
 * The address of the first record is used as an offset
 * so that the first records starts at vector element 0.
 *
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <time.h>
#include <malloc.h>

/* Test for Visual Studio */
#if defined(_MSC_VER)

#pragma warning(disable : 4996)
#include <windows.h>
#include "getopt.h"

/* Test for GCC for Windows*/
#elif defined(WIN32) || defined(WIN64) || defined (WINNT)
#include <getopt.h>
#include <unistd.h>

/* Probably Linux */
#else

#include <getopt.h>
#include <unistd.h>

#endif

#define VERSION "v0.2.1"

/* 1000 should be enough */
#define LEN_BUFFER (1000)

/* This should really be enough */
/* Must be a multple of 8 (DWORD) */
#define LEN_CODE (10000000)

#define BYTE (1)
#define HALFWORD (2)
#define WORD (4)
#define DWORD (8)

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
    time_t t = time(NULL);

    /* Pointer to the buffer */
    unsigned char *code = NULL;
    int codesize = LEN_CODE;

    /* Options */
    int opt;
    int verbose, full;
    int size = BYTE;
    int rev = 0;

    /* Set defaults on options */
    full = 1;
    verbose = 0;

    /* Check for 0 extra arguments */
    if (argc == 1) {
        printf("srec2mif " VERSION " -- an S-record to MIF table converter\n");
        printf("Usage: srec2mif [-vqbhwd] inputfile [outputfile]\n");
        printf("   -v        Verbose\n");
        printf("   -q        Quiet. Only errors are reported\n");
        printf("   -b        Byte output (default)\n");
        printf("   -h        Halfword output (16 bits, Little Endian)\n");
        printf("   -w        Word output (32 bits, Little Endian)\n");
        printf("   -d        Double word output (64 bits, Little Endian)\n");
        printf("   -r        Reverse output (half word, word and double word only)\n\n");
        printf("If outputfile is omitted, stdout is used\n");
        printf("Program size must be less then %d MB\n\n", LEN_CODE/1000000);
        printf("The address of the first record is used as an offset\n"
               "so that the first record starts at address 0.\n");
        exit(EXIT_SUCCESS);
    }

    /* Parse options */
    while ((opt = getopt(argc, argv, "bhwvqdr")) != -1) {
        switch (opt) {
        case 'r':
            rev = 1;
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
        case 'd':
            size = DWORD;
            break;
        case 'q':
            verbose = 0;
        default: /* '?' */
            exit(EXIT_FAILURE);
        }
    }

    if (verbose) {
        fprintf(stderr, "srec2mif " VERSION " \n");
        fprintf(stderr, "S-record to MIF converter\n");
    }

    code = calloc(codesize, sizeof(unsigned char));
    if (code == NULL) {
        fprintf(stderr, "Cannot allocate memory\n");
        exit(EXIT_FAILURE);
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

    /* Print header */
    if (full) {
        fprintf(fout, "-- srec2mif table generator\n");
        fprintf(fout, "-- for input file '%s'\n", argv[optind]);
        fprintf(fout, "-- date: %s\n\n", ctime(&t));
    }

    /* Shift to length of data in array */
    address -= offset;

    if (address > codesize) {
        fprintf(stderr, "Warning: internal buffer too small, not exporting all data!\n");
        address = codesize;
    }

    fprintf(fout, "DEPTH = %lu;\n", address/size);
    fprintf(fout, "WIDTH = %d;\n", size*8);
    fprintf(fout, "ADDRESS_RADIX = HEX;\n");
    fprintf(fout, "DATA_RADIX = HEX;\n");
    fprintf(fout, "\nCONTENT\nBEGIN\n");

    /* Align to next address */
    address = ((address + size - 1) & ~(size - 1));

    /* Output the data */
    for (i = 0; i < address; i = i + size) {

        if (rev) {
            if (size == BYTE) {
                fprintf(fout, "%04X : %02X;", i/size, code[i]);
            } else if (size == HALFWORD) {
                fprintf(fout, "%04X : %02X%02X;", i/size, code[i+1], code[i]);
            } else if (size == WORD) {
                fprintf(fout, "%04X : %02X%02X%02X%02X;", i/size, code[i+3], code[i+2], code[i+1], code[i]);
            } else if (size == DWORD) {
                fprintf(fout, "%04X : %02X%02X%02X%02X%02X%02X%02X%02X;", i/size, code[i+7], code[i+6], code[i+5], code[i+4], code[i+3], code[i+2], code[i+1], code[i]);
            } else {
                fprintf(stderr, "BUG:: size unknown\n");
            }
        } else {
            if (size == BYTE) {
                fprintf(fout, "%04X : %02X;", i/size, code[i]);
            } else if (size == HALFWORD) {
                fprintf(fout, "%04X : %02X%02X;", i/size, code[i], code[i+1]);
            } else if (size == WORD) {
                fprintf(fout, "%04X : %02X%02X%02X%02X;", i/size, code[i], code[i+1], code[i+2], code[i+3]);
            } else if (size == DWORD) {
                fprintf(fout, "%04X : %02X%02X%02X%02X%02X%02X%02X%02X;", i/size, code[i], code[i+1], code[i+2], code[i+3], code[i+4], code[i+5], code[i+6], code[i+7]);
            } else {
                fprintf(stderr, "BUG:: size unknown\n");
            }
        }
        fprintf(fout, "\n");
    }

    if (full) {
        fprintf(fout, "END;\n");
    }

    if (verbose) {
        fprintf(stderr, "Transformed %lu bytes.\n", address);
    }

    fclose(fp);
    fclose(fout);

    return EXIT_SUCCESS;
}
