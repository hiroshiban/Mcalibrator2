classdef brontesLL
  % a class to manipulate Admesy Brontes-LL from MATLAB on Windows OS via a USB port
  %
  % [methods]
  % brontesLL=brontesLL.gen_port('PORT')             : generate USB port to communicate with Brontes-LL
  % brontesLL=brontesLL.initialize(integration_time) : initialize measurement parameters
  % brontesLL=brontesLL.reset_port()                 : reset USB port connection
  % [qq,Y,x,y,brontesLL]=brontesLL.measure(integration_time) : measure CIE1931 xyY
  % command=brontesLL.write('command')               : send command to Brontes-LL through USB connection
  % results=brontesLL.read(number_of_bytes)          : read resutls etc from Brontes-LL through USB connection
  %
  % [requirement]
  % 1. NI-VISA (National Instruments) or lib_usb_win32 driver
  % 2. Admesy_sdk.zip distributed by Admesy, Netherlands
  %
  % [how to use]
  % To use this class on Windows OS with Admesy BrontesLL, please first install
  % Admesy SDK distributed by Admesy, Netherlands.
  % After installing the sdk, please copy three files below
  % ~/Admesy SDK/libraries/libusbtmc/bin/x64/libusbtmc_x64.dll
  % ~/Admesy SDK/libraries/libusbtmc/bin/x86/libusbtmc_x86.dll
  % ~/Admesy SDK/libraries/libusbtmc/include/libusbtmc.h
  % to the same directory with this class file.
  %
  % [license details about Admesy SDK]
  % Admesy SDK license agreement
  % By installing the Admesy SDK, you agree to the following terms.
  % 1)	The Admesy SDK can be used freely with Admesy instruments with no limitations regarding installation.
  % 2)	Use of this library with other brands instruments is not permitted.
  % 3)	This library is not licensed to third parties without the use of Admesy Instruments.
  % 4)	Distribution of the files is only permitted with Admesy instruments or demo software.
  % Distributions should always include this end-user license.
  % 5)	Modifications/renaming of DLLÅfs are not permitted.
  % 6)	Functions that are exported but undocumented, are not supported.
  % 7)	This Admesy License agreement does not contain any 3th party licenses such as Labview,NI-Visa
  %     or Microsoft Visual Studio. 3th party software may require a separate license agreement.
  % 8)	Libusbtmc can be used in conjunction with libusb. This does not require a separate license.
  % 9)	The library is not distributed with source code. It is not open source, but free to use.
  % 10)	The Admesy colour SDK is developed for use on the Windows Operating system (XP32bit, Vista, Win7,
  %     Win8) and with general hardware in mind. Admesy does not guarantee full functionality on all operating
  %     systems/hardware. Admesy Instruments can be operated on Linux and Mac OSX or other Operating systems,
  %     but that is not supported by this SDK.
  % 11)	This SDK and its components are free to use under above terms and may not be sold to 3rd parties.
  %
  %
  % Created    : "2012-10-29 05:28:07 ban"
  % Last Update: "2017-06-30 09:54:20 ban"

  properties (Hidden) %(SetAccess = protected);
    % id of USB port to communicate with Brontes-LL. This is a dummy variable to match with the other function
    portname='USB0::0x1781::0x0E98::00032::INSTR';
    rscom=[];  % serial port object. This is a dummy variable to match with the other function
    deviceID='';
    devicehandle=0;
    TIME_OUT=5000; % time out of the communication in msec
  end

  properties
    init_flg=0;
  end

  methods

    % constructor
    function obj=brontesLL(port_name)
      if ~libisloaded('usbtmc')
        if strfind(computer('arch'),'64') % if working on a 64-bit machine
          %notfound=loadlibrary('libusbtmc_x64.dll',@admesy_libusbtmc_matlab,'alias','usbtmc');
          notfound=loadlibrary('libusbtmc_x64.dll','libusbtmc.h','alias','usbtmc');
        else % if working on a 32-bit machine.
          %notfound=loadlibrary('libusbtmc_x86.dll',@admesy_libusbtmc_matlab,'alias','usbtmc');
          notfound=loadlibrary('libusbtmc_x86.dll','libusbtmc.h','alias','usbtmc');
        end
        if ~isempty(notfound)
          if strfind(computer('arch'),'64') % if working on a 64-bit machine
            error('library: libusbtmc_x64.dll & libusbtmc.h not found. check input variable.');
          else % if working on a 32-bit machine.
            error('library: libusbtmc_x86.dll & libusbtmc.h not found. check input variable.');
          end
        end
      end
      if nargin==1 && ~isempty(port_name)
        obj.portname=port_name;
      end
    end

    % destructor
    function obj=delete(obj)
      obj.rscom=[];
      obj.init_flg=0;
      if obj.devicehandle~=0, calllib('usbtmc','usbtmc_close',obj.devicehandle); end
      unloadlibrary('usbtmc');
    end

    % create/open a USB port connection to communicate with Brontes-LL
    function obj=gen_port(obj,port_name) %#ok
      % port_name is a dummy variable to match nargin with the other functions
      if obj.init_flg==1
        disp('USB connection with Brontes-LL is already established');
      else
        disp('starting USB communication with Brontes-LL');

        % find Brontes-LL device with its ID
        usbtmcdevices=libpointer('stringPtr',repmat(' ',1,255));
        [dummy,obj.deviceID]=calllib('usbtmc','usbtmc_find_devices',usbtmcdevices);
        clear usbtmcdevices;
        if obj.deviceID==0
          warning('USB communication can not be established. check cable connection'); %#ok
          obj.init_flg=0;
        else
          % open USB port
          [dummy,obj.deviceID,obj.devicehandle]=calllib('usbtmc','usbtmc_open',obj.deviceID,0);
          if obj.devicehandle==0
            error('USB port not opend. check cable connection');
          end
          obj.init_flg=1;
        end

      end
    end

    % reset a serial port connection
    function obj=reset_port(obj)
      obj.rscom=[];
      obj.init_flg=0;
      calllib('usbtmc','usbtmc_close',obj.devicehandle);
      obj.deviceID='';
      obj.devicehandle=0;
      [dummy,obj.deviceID,obj.devicehandle]=calllib('usbtmc','usbtmc_open',obj.deviceID,0);
    end

    % initialize Brontes-LL
    function [obj,check,integtime]=initialize(obj,integtime)
      if nargin<=2 || isempty(integtime), integtime=40000; end
      integtime=min(integtime,500000);
      integtime=max(5000,integtime);

      check=0;
      try
        % reset & clear the device
        [dummy,obj.devicehandle]=calllib('usbtmc','usbtmc_write',obj.devicehandle,':*RST',obj.TIME_OUT);
        [dummy,obj.devicehandle]=calllib('usbtmc','usbtmc_write',obj.devicehandle,':*CLS',obj.TIME_OUT);

        % set gain
        [dummy,obj.deviceID]=calllib('usbtmc','usbtmc_write',obj.devicehandle,':SENSE:GAIN 1',obj.TIME_OUT);

        % set num of samples to be averaged
        [dummy,obj.devicehandle]=calllib('usbtmc','usbtmc_write',obj.devicehandle,':SENSE:AVERAGE 10',obj.TIME_OUT);

        % set integration time in usec
        [dummy,obj.devicehandle]=calllib('usbtmc','usbtmc_write',obj.devicehandle,sprintf(':SENSE:INT %d',integtime),obj.TIME_OUT);

        % set sampling band width
        [dummy,obj.devicehandle]=calllib('usbtmc','usbtmc_write',obj.devicehandle,':SENSE:SBW small',obj.TIME_OUT);
      catch %#ok
        check=1;
      end
    end

    % measure CIE1931 xyY of the target
    function [qq,Y,x,y,obj]=measure(obj,integtime)

      if ~obj.init_flg, disp('initialization has not completed. open port and initialize the apparatus first.'); return; end
      if nargin<2 || isempty(integtime), integtime=20000*2; end
      integtime=min(integtime,500000);
      integtime=max(5000,integtime);

      qq=1; counter=0;
      while qq~=0 && counter<5
        counter=counter+1;
        if counter>2
          if qq>0
            integtime=min(ceil(integtime*0.8),5000);
          elseif qq<0
            integtime=min(ceil(integtime*1.2),5000000);
          end
          [dummy,obj.devicehandle]=calllib('usbtmc','usbtmc_write',obj.devicehandle,sprintf(':SENSE:INT %d',integtime),obj.TIME_OUT);
        end

        % [about output format of measured CIE1931 xyY]
        %
        % :MEASure command return their result in ASCII formated floating point as shown below :
        % (Y,x,y,clip,noise) ?® %f,%f,%f,%d,%d\n;
        %
        % The integration time setting can be varied from 0.5ms to 5s.
        % It is specified in É s. Results from the Brontes-LL colorimeter include a clip and noise
        % indication which indicate whether the measured light is too bright (clip) or too low (noise).
        % When clipping is detected, the resulting colour will not be correct and a lower integration time
        % should be chosen. When noise is detected, a larger integration time should be chosen.

        [dummy,obj.devicehandle]=calllib('usbtmc','usbtmc_write',obj.devicehandle,':meas:YXY',obj.TIME_OUT);
        bytecount=64;
        data_ptr=libpointer('uint8Ptr',zeros(1,bytecount));

        % [Note from Admesy SDK manual about the use of Bytecount]
        %
        % The third input variable of usbtmc_read is Bytecount.
        % The number of bytes that needs to be read may exceed the actual data that is available.
        % However, assigning always a very large number is discouraged.
        % For example when a Åg:meas:XYZÅh command returns 36 bytes, you may ask for 64 bytes.
        % When you use a Åg:sample:YÅh function, you know exactly how many bytes should be returned.
        % It is than best to input this exact number or just a little bit more.
        % In case you read for example 65535 bytes for a Åg:meas:XYZ: command, the internal library
        % allocates 65535 bytes where it only gets 36bytes back. This works, but is inefficient in
        % memory and execution time.

        [dummy,obj.devicehandle,measured]=calllib('usbtmc','usbtmc_read',obj.devicehandle,data_ptr,uint32(bytecount),obj.TIME_OUT);
        clear data_ptr;

        val=sscanf(char(measured),'%f,%f,%f,%d,%d\n');
        if val(4)==0 & val(5)==0
          if numel(val)~=0
            Y=val(1);
            x=val(2);
            y=val(3);
            clip=val(4);
            noise=val(5);
            qq=0;
            %if clip, qq=1; end
            %if noise, qq=-1; end
            %if clip==0 && noise==0, qq=0; end
          else
            qq=1; Y=[]; x=[]; y=[];
          end
        else
          if val(4)==0
            warning('the measured light is too bright'); %#ok
          elseif val(5)==0
            warning('the measured light is too dark'); %#ok
          end
          qq=1; Y=[]; x=[]; y=[];
        end
      end
    end

    % write command to Brontes-LL through USB connection
    function [obj,command]=write(obj,command)
      calllib('usbtmc','usbtmc_write',obj.devicehandle,command,obj.TIME_OUT);
    end

    % read results etc from Brontes-LL through USB connection
    function [obj,results]=read(obj,bytecount)
      if nargin<2 || ismepty(bytecount), bytecount=128; end
      data_ptr=libpointer('uint8Ptr',zeros(1,bytecount));
      [dummy,obj.devicehandle,results]=calllib('usbtmc','usbtmc_read',obj.devicehandle,data_ptr,uint32(bytecount),obj.TIME_OUT);
      results=char(results);
      clear data_ptr;
    end

  end % methods

end % classdef brontesLL
