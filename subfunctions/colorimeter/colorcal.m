classdef colorcal
  % a class to manipulate Cambridge Research Systems ColorCal from MATLAB through a USB connection
  %
  % [methods]
  % colorcal=colorcal.gen_port('PORT')             : generate USB port to communicate with ColorCAL
  % colorcal=colorcal.initialize(integration_time) : initialize measurement parameters
  % colorcal=colorcal.reset_port()                 : reset USB port connection
  % colorcal=colorcal.autocalibrate()              : calibrate ColorCAL automatically
  % [qq,Y,x,y,colorcal]=colorcal.measure(integration_time) : measure CIE1931 xyY
  % [qq,vol,colorcal]=colorcal.measureVoltage(integration_time) : measure voltage
  % [qq,lum,colorcal]=colorcal.measureLuminance(integration_time) : measure luminance
  %
  % [NOTE]
  % requires CalibInterface.h & Calibrator.lib distributed by Cambridge Research Systems.
  %
  % [Basic functions available by loading CalibInterface.h & Calibrator.lib]
  %
  % // Use these functions for simple use of the OptiCAL. They will allow you to take
  % // readings of Voltage or Luminance, and contain all the calculations and conversions
  % // required. They all return '0' if they are successful, or '1' if there is an error.
  %
  % // Initialise the OptiCAL. Open communication on the given port (OptiCAL_Location =
  % // OptiCAL_COM1, OptiCAL_COM2, OptiCAL_USB, etc)... Then calibrate the OptiCAL, read
  % // back the EEPROM calibration parameters, and set Luminance mode.
  % // This function must be called before any of the others.
  % // The returned value is a handle to the device.  Use this when processing
  % // multiple devices
  % int calInitialise(int Device);
  %
  % // Read a luminance value (in cd/m²) back from the device
  % // To convert this to fL, divide by 3.426259101
  % int calReadLuminance(double *Luminance);
  %
  % // Read a voltage (in Volts) value back from the device
  % // To convert this to mV, Multiply by 1000
  % int calReadVoltage(double *Voltage);
  %
  % // Read a colour in CIE x,y,l back from the device
  % // returns CALIB_NOTSUPPORTED and (0,0,luminance) if colour feature is not supported by the device
  % int calReadColour(double *CieX, double *CieY, double *CieLum);
  %
  % // Close communication with the device.
  % // Call this procedure before closing your program.
  % int calCloseDevice(void);
  %
  % // Call this to perform a auto calibration of the device.
  % // This is performed automatically during calInitialise. The procedure
  % // may differ depending on the device type.
  % int calAutoCalibrate(void);
  %
  % //***************************   ADVANCED FUNCTIONS   ***************************
  % //************ Do not use these.  The four functions above should be ***********
  % //************     sufficient for simple optical applications        ***********
  % //******************************************************************************
  %
  % //Open communications device
  % //     This function should not normally be used.
  % //     Use calInitialise instead
  % //         ==================
  % //     'DeviceType' is the device to open (DEVICE_OPTICAL_COM1, DEVICE_COLORCAL_USB etc)
  % //     Function returns '0' if successful or '1' if an error occurs.
  % //     This function does not prepare the system for reading luminances.
  % //     i.e it does not autocalibrate read back params etc
  % int calOpenDevice(int DeviceType);
  %
  % //Set OptiCAL mode.
  % //    'Mode' is 'C'=Calibrate, 'V'=Voltage, 'I'=Luminance
  % //    This function _must_ be called straight after opening the device
  % //     Function returns '0' if successful or '1' if an error occurs.
  % int calSetMode(char Mode);
  %
  % //Read back all the calibration parameters from the OptiCAL
  % //     'OpticalParams' is a structure of type 'PARAMS' and contains all the calibration parameters
  % //     This function _must_ be called before attempting to read the ADC value.
  % //     Function returns '0' if successful or '1' if an error occurs.
  % int calReadDeviceParams(calDeviceConfigurationParams *Params);
  %
  % //Read back an ADC value from the OptiCAL ADC
  % //     'Value' is a long integer in which the ADC value will be placed.
  % //     Function returns '0' if successful or '1' if an error occurs.
  % int calReadADCValue(long *Value);
  %
  % //This function allows CRS personnel to configure the Optical's internal
  % //calibration factors
  % int calWriteDeviceParams(int AccessMode, int ParameterToWrite, calDeviceConfigurationParams *Params);
  %
  % // Return the calibrators operation modes
  % int calGetCapabilities(calDeviceCapabilities *DC);
  %
  %
  % Created    : "2012-04-11 09:23:57 ban"
  % Last Update: "2013-12-08 16:58:27 ban (ban.hiroshi@gmail.com)"

  properties (Hidden) %(SetAccess = protected);
    portname=6; % id of USB port to communicate with ColorCal
    rscom=[];  % serial port object, dummy but required
    % some constant variables, extracted from crsLoadConstants.m in CRS toolbox for MATLAB
    DEVICE_COLORCAL_USB  = 6;
    CALIB_OK             = 0;
    CALIB_COMMERROR      = 1;
    CALIB_OVERFLOW       = 2;
    CALIB_NOTINITIALISED = 3;
    CALIB_NOTSUPPORTED   = 4;
  end

  properties
    init_flg=0;
  end

  methods

    % constructor
    function obj=colorcal(port_name)
      if nargin==1 && ~isempty(port_name)
        obj.portname=port_name;
      else
        obj.portname=6;
      end
      if ~libisloaded('Calibrator')
        notfound=loadlibrary('Calibrator',which('CalibInterface.h'));
        if ~isempty(notfound)
          error('library: Calibrator.lib & CalibInterface.h not found. check input variable.');
        end
      end
    end

    % destructor
    function obj=delete(obj)
      obj.rscom=[];
      if obj.init_flg==1
        if libisloaded('Calibrator')
          calllib('Calibrator','calCloseDevice');
          unloadlibrary('Calibrator');
        end
      end
      obj.init_flg=0;
    end

    % create/open a USB port connection to communicate with ColorCAL
    function obj=gen_port(obj,port_name) %#ok
      % port_name is a dummy variable to match nargin with the other functions
      if obj.init_flg==1
        disp('USB connection with ColorCAL is already established');
      else
        disp('starting USB communication with ColorCAL');

        % open USB port
        ErrorCode=calllib('Calibrator','calInitialise',obj.DEVICE_COLORCAL_USB);

        % check errors
        % obj.CALIB_OK             = 0;
        % obj.CALIB_COMMERROR      = 1;
        % obj.CALIB_OVERFLOW       = 2;
        % obj.CALIB_NOTINITIALISED = 3;
        % obj.CALIB_NOTSUPPORTED   = 4;
        if ErrorCode==obj.CALIB_OK
          obj.init_flg=1;
        elseif ErrorCode==obj.CALIB_COMMERROR
          error('COM port error. check device connection');
        elseif ErrorCode==obj.CALIB_OVERFLOW
          error('OVERFLOW error. check device connection');
        elseif ErrorCode==obj.CALIB_NOTINITIALISED
          error('Initialization failed. check device connection');
        elseif ErrorCode==obj.CALIB_NOTSUPPORTED
          error('unspecified error. check device connection and input variable.');
        end
      end
    end

    % reset USB port connection
    function obj=reset_port(obj)
      % close the port
      obj.rscom=[];
      obj.init_flg=0;
      calllib('Calibrator','calCloseDevice');
      % open the port again
      ErrorCode=calllib('Calibrator','calInitialise',obj.DEVICE_COLORCAL_USB);

      % check errors
      % obj.CALIB_OK             = 0;
      % obj.CALIB_COMMERROR      = 1;
      % obj.CALIB_OVERFLOW       = 2;
      % obj.CALIB_NOTINITIALISED = 3;
      % obj.CALIB_NOTSUPPORTED   = 4;
      if ErrorCode==obj.CALIB_OK
        % do nothing
      elseif ErrorCode==obj.CALIB_COMMERROR
        error('COM port error. check device connection');
      elseif ErrorCode==obj.CALIB_OVERFLOW
        error('OVERFLOW error. check device connection');
      elseif ErrorCode==obj.CALIB_NOTINITIALISED
        error('Initialization failed. check device connection');
      elseif ErrorCode==obj.CALIB_NOTSUPPORTED
        error('unspecified error. check device connection and input variable.');
      end
    end

    % initialize ColorCal
    function [obj,check,integtime]=initialize(obj,integtime)
      % "integtime" is a dummy variable to match the function format with the other device object.
      if nargin<=2 || isempty(integtime), integtime=0; end

      % just check whether ColorCAL library is loaded on MATLAB
      check=0; %#ok
      if obj.init_flg==1
        % do nothing
        check=1;
      else
        if ~libisloaded('Calibrator')
          check=0;
          warning('library: Calibrator.lib & CalibInterface.h not loaded yet. check input variable.'); %#ok
        else
          check=1;
        end
      end
    end

    % calibrate ColorCAL automatically
    function obj=autocalibrate(obj)
      ErrorCode=calllib('Calibrator','calAutoCalibrate');

      % check errors
      % obj.CALIB_OK             = 0;
      % obj.CALIB_COMMERROR      = 1;
      % obj.CALIB_OVERFLOW       = 2;
      % obj.CALIB_NOTINITIALISED = 3;
      % obj.CALIB_NOTSUPPORTED   = 4;
      if ErrorCode==obj.CALIB_OK
        obj.init_flg=1;
      elseif ErrorCode==obj.CALIB_COMMERROR
        error('COM port error. check device connection');
      elseif ErrorCode==obj.CALIB_OVERFLOW
        error('OVERFLOW error. check device connection');
      elseif ErrorCode==obj.CALIB_NOTINITIALISED
        error('Initialization failed. check device connection');
      elseif ErrorCode==obj.CALIB_NOTSUPPORTED
        error('unspecified error. check device connection and input variable.');
      end
    end

    % measure CIE1931 xyY of the target
    function [qq,Y,x,y,obj]=measure(obj,integtime)
      % integtime is a dummy variable to match input variables with the other functions
      if nargin<2 || isempty(integtime)
        integtime=0; %#ok
      end

      qq=1; counter=0;
      while qq~=0 && counter<5
        counter=counter+1;

        x = libpointer('doublePtr',0);
        y = libpointer('doublePtr',0);
        Y = libpointer('doublePtr',0);
        [ErrorCode,x,y,Y]= calllib('Calibrator','calReadColour',x,y,Y);

        % check errors
        % obj.CALIB_OK             = 0;
        % obj.CALIB_COMMERROR      = 1;
        % obj.CALIB_OVERFLOW       = 2;
        % obj.CALIB_NOTINITIALISED = 3;
        % obj.CALIB_NOTSUPPORTED   = 4;
        if ErrorCode==obj.CALIB_OK
          qq=0;
        elseif ErrorCode==obj.CALIB_COMMERROR
          qq=1;
          x = nan;
          y = nan;
          Y = nan;
          if counter==4
            warning('COM port error. check device connection'); %#ok
          end
        elseif ErrorCode==obj.CALIB_OVERFLOW
          qq=1;
          x = nan;
          y = nan;
          Y = nan;
          if counter==4
            warning('OVERFLOW error. check device connection'); %#ok
          end
        elseif ErrorCode==obj.CALIB_NOTINITIALISED
          qq=1;
          x = nan;
          y = nan;
          Y = nan;
          if counter==4
            warning('Initialization failed. check device connection'); %#ok
          end
        elseif ErrorCode==obj.CALIB_NOTSUPPORTED
          qq=1;
          x = nan;
          y = nan;
          Y = nan;
          if counter==4
            warning('unspecified error. check device connection and input variable.'); %#ok
          end
        end
      end % while qq~=0 && counter<5
    end

    % measure voltage of the target
    function [qq,vol,obj]=measureVoltage(obj,integtime)
      % integtime is a dummy variable to match input variables with the other functions
      if nargin<2 || isempty(integtime)
        integtime=0; %#ok
      end

      qq=1; counter=0;
      while qq~=0 && counter<5
        counter=counter+1;

        vol = libpointer('doublePtr',0);
        [ErrorCode,vol]= calllib('Calibrator','calReadVoltage',vol);
        vol=get(vol,'Value');

        % check errors
        % obj.CALIB_OK             = 0;
        % obj.CALIB_COMMERROR      = 1;
        % obj.CALIB_OVERFLOW       = 2;
        % obj.CALIB_NOTINITIALISED = 3;
        % obj.CALIB_NOTSUPPORTED   = 4;
        if ErrorCode==obj.CALIB_OK
          qq=0;
        elseif ErrorCode==obj.CALIB_COMMERROR
          qq=1;
          vol = nan;
          if counter==4
            warning('COM port error. check device connection'); %#ok
          end
        elseif ErrorCode==obj.CALIB_OVERFLOW
          qq=1;
          vol = nan;
          if counter==4
            warning('OVERFLOW error. check device connection'); %#ok
          end
        elseif ErrorCode==obj.CALIB_NOTINITIALISED
          qq=1;
          vol = nan;
          if counter==4
            warning('Initialization failed. check device connection'); %#ok
          end
        elseif ErrorCode==obj.CALIB_NOTSUPPORTED
          qq=1;
          vol = nan;
          if counter==4
            warning('unspecified error. check device connection and input variable.'); %#ok
          end
        end
      end % while qq~=0 && counter<5
    end

    % measure luminance of the target
    function [qq,lum,obj]=measureLuminance(obj,integtime)
      % integtime is a dummy variable to match input variables with the other functions
      if nargin<2 || isempty(integtime)
        integtime=0; %#ok
      end

      qq=1; counter=0;
      while qq~=0 && counter<5
        counter=counter+1;

        lum = libpointer('doublePtr',0);
        [ErrorCode,lum]= calllib('Calibrator','calReadLuminance',lum);
        lum=get(lum,'Value');

        % check errors
        % obj.CALIB_OK             = 0;
        % obj.CALIB_COMMERROR      = 1;
        % obj.CALIB_OVERFLOW       = 2;
        % obj.CALIB_NOTINITIALISED = 3;
        % obj.CALIB_NOTSUPPORTED   = 4;
        if ErrorCode==obj.CALIB_OK
          qq=0;
        elseif ErrorCode==obj.CALIB_COMMERROR
          qq=1;
          lum = nan;
          if counter==4
            warning('COM port error. check device connection'); %#ok
          end
        elseif ErrorCode==obj.CALIB_OVERFLOW
          qq=1;
          lum = nan;
          if counter==4
            warning('OVERFLOW error. check device connection'); %#ok
          end
        elseif ErrorCode==obj.CALIB_NOTINITIALISED
          qq=1;
          lum = nan;
          if counter==4
            warning('Initialization failed. check device connection'); %#ok
          end
        elseif ErrorCode==obj.CALIB_NOTSUPPORTED
          qq=1;
          lum = nan;
          if counter==4
            warning('unspecified error. check device connection and input variable.'); %#ok
          end
        end
      end % while qq~=0 && counter<5
    end

  end % methods

end % classdef colorcal
