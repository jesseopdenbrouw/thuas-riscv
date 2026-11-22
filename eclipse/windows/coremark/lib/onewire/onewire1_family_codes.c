/*
 * 1-Wire family codes
 *
 * Family codes are the first byte of a 1-Wire ROM ID.
 * This is a practical list of common Analog Devices / Maxim devices,
 * not an exhaustive registry. Some families contain multiple device models.
 */

#include <thuasrv32.h>

static const onewire_family_code_t onewire_family_codes[] = {
    {0x01, "DS1990A, DS1990R, DS2401, DS2411", "Serial number"},
    {0x02, "DS1991", "Secure memory, 1152-bit"},
    {0x04, "DS1994, DS2404", "RAM, clock and timer"},
    {0x05, "DS2405", "Addressable switch"},
    {0x06, "DS1993", "4 Kbit NV RAM"},
    {0x08, "DS1992", "1 Kbit NV RAM"},
    {0x09, "DS1982, DS2502", "1 Kbit EPROM"},
    {0x0A, "DS1995", "16 Kbit NV RAM"},
    {0x0B, "DS1985, DS2505", "16 Kbit EPROM"},
    {0x0C, "DS1996", "64 Kbit NV RAM"},
    {0x0F, "DS1986, DS2506", "64 Kbit EPROM"},
    {0x10, "DS18S20, DS1920", "Temperature sensor"},
    {0x12, "DS2406, DS2407", "Dual-channel switch"},
    {0x14, "DS1971, DS2430A", "256-bit EEPROM"},
    {0x16, "DS1954, DS1957", "Cryptographic iButton"},
    {0x18, "DS1962, DS1963S", "SHA-1 secure memory"},
    {0x1A, "DS1963L", "4 Kbit NV RAM with counters"},
    {0x1B, "DS2436", "Battery monitor"},
    {0x1C, "DS28E04-100", "4 Kbit EEPROM, PIO"},
    {0x1D, "DS2423", "4 Kbit RAM with counters"},
    {0x1E, "DS2437", "Smart battery monitor"},
    {0x1F, "DS2409", "MicroLAN coupler"},
    {0x20, "DS2450", "4-channel ADC"},
    {0x21, "DS1921G, DS1921H, DS1921Z", "Temperature logger"},
    {0x22, "DS1822", "Econo digital thermometer"},
    {0x23, "DS1973, DS2433", "4 Kbit EEPROM"},
    {0x24, "DS1904, DS2415", "Real-time clock"},
    {0x26, "DS2438", "Smart battery monitor"},
    {0x27, "DS2417", "RTC with interrupt"},
    {0x28, "DS18B20", "Digital temperature sensor"},
    {0x29, "DS2408", "8-channel addressable switch"},
    {0x2C, "DS2890", "Digital potentiometer"},
    {0x2D, "DS1972, DS2431", "1 Kbit EEPROM"},
    {0x2E, "DS2770", "Battery monitor and charger"},
    {0x30, "DS2760, DS2762", "Lithium battery monitor"},
    {0x31, "DS2720", "Single-cell battery protection"},
    {0x32, "DS2780", "Fuel gauge"},
    {0x33, "DS1961S, DS2432", "1 Kbit EEPROM with SHA-1"},
    {0x34, "DS2703", "Battery authentication"},
    {0x35, "DS2755", "Fuel gauge"},
    {0x36, "DS2740", "Coulomb counter"},
    {0x37, "DS1977", "32 KB password-protected EEPROM"},
    {0x3A, "DS2413", "Dual-channel switch"},
    {0x3B, "DS1825, MAX31826, MAX31850", "Temperature sensor / thermocouple"},
    {0x3D, "DS2781", "Fuel gauge"},
    {0x41, "DS1922L, DS1922T, DS1923, DS2422", "Temperature and humidity loggers"},
    {0x42, "DS28EA00", "Temperature sensor with sequence detection"},
    {0x43, "DS28EC20", "20 Kbit EEPROM"},
    {0x44, "DS28E10", "SHA-1 authenticator"},
    {0x51, "DS2751", "Battery fuel gauge"},
    {0x53, "DS1925", "Temperature logger"},

    /* Additional and less common codes */
    {0x7E, "EDS00xx", "EDS sensor adapter"},
    {0x81, "USBID, DS1420", "Identification"},
    {0x82, "DS1425", "Identification with protected RAM"},
    {0xA0, "mRS001", "Custom device"},
    {0xA1, "mVM0011", "Custom device"},
    {0xA2, "mCM001", "Custom device"},
    {0xA6, "mTS017", "Custom device"},
    {0xB1, "mTC001", "Custom device"},
    {0xB2, "mAM001", "Custom device"},
    {0xB3, "mTC002", "Custom device"},
    {0xEE, "mTC002", "Custom device"},
    {0xEF, "Moisture Hub", "Moisture sensor interface"},
    {0xF0, "MOAT", "Custom microcontroller slave"},
    {0xFC, "BAE0910, BAE0911", "Custom devices"},
    {0xFF, "Swart LCD", "LCD interface"},
    {0x00, NULL, NULL}
};

const onewire_family_code_t *onewire1_getcred(uint8_t fam_code)
{
	for (int i = 0; onewire_family_codes[i].code != 0x00; i++) {
		if (onewire_family_codes[i].code == fam_code) {
			return &onewire_family_codes[i];
		}
	}

	return NULL;
}
