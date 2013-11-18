//******************************************************************************
//
//     CalibInterface.h - MSVC interface to Calibrator.dll
//
//     Copyright 2001 Cambridge Research Systems Ltd
//
//     Written by Robert Shiells
//
//******************************************************************************

#ifdef __cplusplus
extern "C"
{
#endif

//******************************************************************************

#define DEVICE_OPTICAL_COM1  1
#define DEVICE_OPTICAL_COM2  2
#define DEVICE_OPTICAL_COM3  3
#define DEVICE_OPTICAL_COM4  4
#define DEVICE_OPTICAL_USB   5
#define DEVICE_COLORCAL_USB  6

#define CALIB_OK              0
#define CALIB_COMMERROR       1
#define CALIB_OVERFLOW        2
#define CALIB_NOTINITIALISED  3
#define CALIB_NOTSUPPORTED    4

#define CAP_LUMINANCE         1
#define CAP_CIECOLOUR         2
#define CAP_SPECTRUM          4
#define CAP_VOLTMETER         8

//******************************************************************************

typedef struct
{
    long RefVoltage;
    long ZeroError;
    long FeedbackRes;
    long VGainRes;
    char ProbeSN[128];
    long ProbeCal;
} calOptiCALSpecificParameters;

typedef struct
{
    double IntegrationTime;
    double CompensationMatrix[9];  // NOTE: This is 0..8 (not 1..9 as in Delphi)
} calColorCALSpecificParameters;

typedef struct
{
    long DeviceType;
    long DeviceVersion;
    long SerialNumber;
    long FirmwareVers;
    calOptiCALSpecificParameters OptiCALParams;
    calColorCALSpecificParameters ColorCALParams;
} calDeviceConfigurationParams;

typedef struct
{
    int Size;
    int CapabilityFlags;
    int MinSampleTime;
} calDeviceCapabilities;

#define OPTICAL_WRITE_PRODUCTTYPE      1
#define OPTICAL_WRITE_OPTICALSN        2
#define OPTICAL_WRITE_FIRMWAREVERSION  4
#define OPTICAL_WRITE_REFVOLTAGE       8
#define OPTICAL_WRITE_ZEROERROR        16
#define OPTICAL_WRITE_FEEDBACKRES      32
#define OPTICAL_WRITE_VGAINRES         64
#define OPTICAL_WRITE_PROBESN          128
#define OPTICAL_WRITE_PROBECAL         256
#define COLORCAL_WRITE_COMPENSATION    512

//******************************************************************************
//*****************************   BASIC FUNCTIONS   ****************************
//******************************************************************************
//Use these functions for simple use of the OptiCAL. They will allow you to take
//readings of Voltage or Luminance, and contain all the calculations and conversions
// required. They all return '0' if they are successful, or '1' if there is an error.

// Initialise the OptiCAL. Open communication on the given port (OptiCAL_Location =
// OptiCAL_COM1, OptiCAL_COM2, OptiCAL_USB, etc)... Then calibrate the OptiCAL, read
// back the EEPROM calibration parameters, and set Luminance mode.
// This function must be called before any of the others.
// The returned value is a handle to the device.  Use this when processing
// multiple devices
int calInitialise(int Device);

// Read a luminance value (in cd/m²) back from the device
// To convert this to fL, divide by 3.426259101
int calReadLuminance(double *Luminance);

// Read a voltage (in Volts) value back from the device
// To convert this to mV, Multiply by 1000
int calReadVoltage(double *Voltage);

// Read a colour in CIE x,y,l back from the device
// returns CALIB_NOTSUPPORTED and (0,0,luminance) if colour feature is not supported by the device
int calReadColour(double *CieX, double *CieY, double *CieLum);

// Close communication with the device.
// Call this procedure before closing your program.
int calCloseDevice(void);

// Call this to perform a auto calibration of the device.
// This is performed automatically during calInitialise. The procedure
// may differ depending on the device type.
int calAutoCalibrate(void);

//******************************************************************************
//******************************************************************************
//******************************************************************************
//******************************************************************************
//******************************************************************************
//******************************************************************************
//******************************************************************************
//******************************************************************************
//******************************************************************************
//******************************************************************************
//******************************************************************************
//******************************************************************************
//******************************************************************************
//******************************************************************************
//******************************************************************************
//******************************************************************************
//***************************   ADVANCED FUNCTIONS   ***************************
//************ Do not use these.  The four functions above should be ***********
//************     sufficient for simple optical applications        ***********
//******************************************************************************

    //Open communications device
    //     This function should not normally be used.
    //     Use calInitialise instead
    //         ==================
    //     'DeviceType' is the device to open (DEVICE_OPTICAL_COM1, DEVICE_COLORCAL_USB etc)
    //     Function returns '0' if successful or '1' if an error occurs.
    //     This function does not prepare the system for reading luminances.
    //     i.e it does not autocalibrate read back params etc
       int calOpenDevice(int DeviceType);

    //Set OptiCAL mode.
    //    'Mode' is 'C'=Calibrate, 'V'=Voltage, 'I'=Luminance
    //    This function _must_ be called straight after opening the device
    //     Function returns '0' if successful or '1' if an error occurs.
       int calSetMode(char Mode);

    //Read back all the calibration parameters from the OptiCAL
    //     'OpticalParams' is a structure of type 'PARAMS' and contains all the calibration parameters
    //     This function _must_ be called before attempting to read the ADC value.
    //     Function returns '0' if successful or '1' if an error occurs.
       int calReadDeviceParams(calDeviceConfigurationParams *Params);

    //Read back an ADC value from the OptiCAL ADC
    //     'Value' is a long integer in which the ADC value will be placed.
    //     Function returns '0' if successful or '1' if an error occurs.
       int calReadADCValue(long *Value);

    //This function allows CRS personnel to configure the Optical's internal
    //calibration factors
       int calWriteDeviceParams(int AccessMode, int ParameterToWrite, calDeviceConfigurationParams *Params);

    // Return the calibrators operation modes
       int calGetCapabilities(calDeviceCapabilities *DC);

//******************************************************************************

#ifdef __cplusplus
};
#endif
