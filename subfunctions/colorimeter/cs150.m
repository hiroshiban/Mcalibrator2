classdef cs150
  % a class to manipulate Konica Minolta CS-150 from MATLAB through a USB port with a virtual serial connection
  % note 1: Dynammic Link Libraries (DLLs) distributed by Konica-Minolta for CS150 are required to use this class.
  %         All the DLLs should be put in fullfile(fileparts(mfilename('fullpath')),'konica_minolta_dlls').
  % note 2: Zero-calibration and chromaticity calibration should be done separately before using CS-150.
  %
  %
  % Created    : "2016-09-26 15:24:46 ban"
  % Last Update: "2016-09-27 16:15:27 ban"

  properties (Hidden) %(SetAccess = protected)
    port_name='COM1'; % id of serial port to communicate with CS-100A
    rscom=[];  % serial port object. This is a dummy variable to match with the other function
    sdk=[];
  end

  properties
    init_flg=0;
  end

  methods

    % constructor
    function obj=cs150(port_name)
      % check whether the .NET assembly, "LC-MISDK", is already loaded or not
      if isempty(which('Konicaminolta.LightColorMISDK'))
        try
          % Loading the .NET assembly
          % Here the classes below are loaded
          % 'Konicaminolta.LightColorMISDK'
          % 'Konicaminolta.ColorSpaceList'
          % 'Konicaminolta.MeasurementData'
          % 'Konicaminolta.XYZ'
          % 'Konicaminolta.Lvxy'
          % 'Konicaminolta.Lvudvd'
          % 'Konicaminolta.LvTcpDuv'
          % 'Konicaminolta.LvDwPe'
          % 'Konicaminolta.Lv'
          % 'Konicaminolta.DeviceInfo'
          % 'Konicaminolta.MeasurementTime'
          % 'Konicaminolta.MeasurementFrequency'
          % 'Konicaminolta.ColorCorrectionFactor'
          % 'Konicaminolta.ReturnMessage'
          % 'Konicaminolta.ErrorDefine'
          % 'Konicaminolta.UserCalibData'
          NET.addAssembly(fullfile(fileparts(mfilename('fullpath')),'konica_minolta_dlls','LC-MISDK.dll'));

          % generate the instance to communicate with Konica-Minolta CS150
          obj.sdk=Konicaminolta.LightColorMISDK.GetInstance();
        catch
          error('Failed to load .NET assembly into MATLAB. check the input variables and library structures.');
        end
      end
      if nargin==1 && ~isempty(port_name)
        obj.port_name=port_name;
      end
    end

    % destructor
    function obj=delete(obj)
      obj.rscom=[];
      obj.init_flg=0;
      if ~isempty(obj.sdk), obj.sdk.Disconnect(str2num(strrep(obj.port_name,'COM',''))); end

      % Here, we should unload the .NET assemby...However, accourding to MathWorks support site...
      % Rebooting is the only solution to this problem for the current Matlab Version (8.1.0.604, R2013a):
      % "The ability to unload an assembly is not available in MATLAB at this point of time. This may be
      % addressed in one of the future releases. Currently, to work around this issue, restart MATLAB."
      %
      % Therefore, we don't do anything
    end

    % create/open a serial port connection to communicate with CS-100A
    function obj=gen_port(obj,port_name)
      if nargin>1 && ~isempty(port_name), obj.port_name=port_name; end

      if obj.init_flg==1
        disp('USB connection with CS-150 is already established');
      else
        disp('starting USB communication with CS-150');
        if ~isempty(obj.sdk)
          % connect to CS-150
          ret=obj.sdk.Connect(str2num(strrep(obj.port_name,'COM','')));
          if ret.errorCode~=Konicaminolta.ErrorDefine.KmSuccess
            error('failed to connect to CS-150. check the port number and physical cable connections.');
            obj.init_flg=0;
          else
            obj.init_flg=1;
          end
        else
          warning('The instance to communicate with CS-150 has been corrupted. check the initialization procedures and cable connections.');
          obj.init_flg=0;
        end
      end
    end

    % reset a serial port connection
    function obj=reset_port(obj)
      obj.rscom=[];
      obj.init_flg=0;
      if ~isempty(obj.sdk), obj.sdk.Disconnect(str2num(strrep(obj.port_name,'COM',''))); end
    end

    % initialize CS-150
    function [obj,check,integtime]=initialize(obj,integtime)
      if nargin<=2 || isempty(integtime), integtime=0.4; end
      if ~isempty(obj.sdk)
        ret=obj.sdk.MeasurementTime(integtime,str2num(strrep(obj.port_name,'COM','')));
        if ret.errorCode~=Konicaminolta.ErrorDefine.KmSuccess
          warning('failed to set measurement time of CS-150. check the port number and physical cable connections.');
        end
      else
        warning('The instance to communicate with CS-150 has been corrupted. check the initialization procedures and cable connections.');
        return
      end

      if ~obj.init_flg
        disp('generate a virtual port to communicate with ColorCal first.');
        check=0;
      else
        % erase debris
        if ~isempty(obj.sdk)
          data_ptr=libpointer('int32Ptr',0);
          ret=obj.sdk.GetNumberOfSampleData(data_ptr);
          clear data_ptr;
          if ret.errorCode~=Konicaminolta.ErrorDefine.KmSuccess
            warning('failed to get the number of sample data. skipping...');
            return
          end
          tmp_data_structure=Konicaminolta.XYZ;
          xyz_ptr=libpointer('c_struct',tmp_data_structure);
          for ii=1:1:data_ptr
            obj.sdk.ReadSampleData(ii,xyz_ptr); % read all
          end
          clear xyz_ptr;
        else
          error('The instance to communicate with CS-150 has been corrupted. check the initialization procedures and cable connections.');
        end
      end
    end

    % measure CIE1931 xyY of the target
    function [qq,Y,x,y,obj]=measure(obj,integtime)
      if nargin<=2 || isempty(integtime), integtime=0.4; end
      if ~isempty(obj.sdk)
        ret=obj.sdk.MeasurementTime(integtime,str2num(strrep(obj.port_name,'COM','')));
        if ret.errorCode~=Konicaminolta.ErrorDefine.KmSuccess
          warning('failed to set measurement time of CS-150. check the port number and physical cable connections.');
        end
      else
        error('The instance to communicate with CS-150 has been corrupted. check the initialization procedures and cable connections.');
      end

      % measurement
      ret=obj.sdk.Measure();
      if ret.errorCode~=Konicaminolta.ErrorDefine.KmSuccess
        warning('failed to measure XYZ...check the port setup and the cable connections.');
        return
      end

      % polling status of measurement
      meas_ptr=libpointer('strPtr',repmat(' ',[1,255]));
      state='Measuring';
      while strcmpi(state,Konicaminolta.MeasStatus.Measuring)
        ret=obj.sdk.PollingMeasurement(meas_ptr);
        if ret.errorCode~=Konicaminolta.ErrorDefine.KmSuccess
          error('failed to poll the measured data. check the port number and physical cable connections.');
        end
      end
      clear meas_ptr;

      % get measured value as (X,Y,Z)
      xyz_data=Konicaminolta.XYZ;
      xyz_ptr=libpointer('c_struct',xyz_data);
      ret=obj.sdk.ReadLatestData(xyz_ptr);
      if ret.errorCode~=Konicaminolta.ErrorDefine.KmSuccess
        warning('failed to read the latest data XYZ...check the port setup and the cable connections.');
      end

      % convert the unit from XYZ to CIE1931 xyY values
      XYZ=[xyz_ptr.X;xyz_ptr.Y;xyz_ptr.Z];
      denom=sum(XYZ,1);
      xyY=[XYZ(1:2)./denom; XYZ(2)];
      x=xyY(1); y=xyY(2); Y=xyY(3);

      clear xyz_ptr;
    end

    % get device information (virtual port ID, machine name, serial number)
    function [obj,device_data]=get_device_list(obj)
      device_data.key=0;
      device_data.value='';
      device_ptr=libpointer('c_struct',device_data);
      if ~isempty(obj.sdk)
        ret=obj.sdk.GetDeviceList(device_ptr);
        if ret.errorCode~=Konicaminolta.ErrorDefine.KmSuccess
          warning('failed to get device information...check the port setup and the cable connections.');
        end
      else
        error('The instance to communicate with CS-150 has been corrupted. check the initialization procedures and cable connections.');
      end
      device_data.key=device_ptr.key;
      device_data.value=device_ptr.value;
      clear device_ptr;
    end

    % turn the backlight on/off
    function obj=set_backlight(obj,port_name)
      if nargin>1 && ~isempty(port_name), obj.port_name=port_name; end
      if ~isempty(obj.sdk)
        backlight_ptr=libpointer('strPtr',repmat(' ',[1,255]));
        ret=obj.sdk.GetBackLightOnOff(backlight_ptr,str2num(strrep(obj.port_name,'COM','')));
        if ret.errorCode~=Konicaminolta.ErrorDefine.KmSuccess
          warning('failed to get BackLightMode. check the port number and physical cable connections.');
        end
        if strcmpi(deblank(backlight_ptr),'Off')
          on_off='On';
        elseif strcmpi(deblank(backlight_ptr),'On')
          on_off='Off';
        end
        clear backlight_ptr;
        ret=obj.sdk.SetBackLightOnOff(on_off,str2num(strrep(obj.port_name,'COM','')));
        if ret.errorCode~=Konicaminolta.ErrorDefine.KmSuccess
          warning('failed to set BackLightMode. check the port number and physical cable connections.');
        end
      else
        error('The instance to communicate with CS-150 has been corrupted. check the initialization procedures and cable connections.');
      end
    end

  end % methods

end % classdef cs150
