classdef brontesLL
  % a class to manipulate Admesy Brontes-LL from MATLAB through a USB port
  %
  % [methods]
  % brontesLL=brontesLL.gen_port('PORT')             : generate USB port to communicate with Brontes-LL
  % brontesLL=brontesLL.initialize(integration_time) : initialize measurement parameters
  % brontesLL=brontesLL.reset_port()                 : reset USB port connection
  % [qq,Y,x,y,brontesLL]=brontesLL.measure(integration_time) : measure CIE1931 xyY
  % command=brontesLL.write('command')               : send command to Brontes-LL through USB connection
  % results=brontesLL.read()                         : read resutls etc from Brontes-LL through USB connection
  %
  % [requirement]
  % NI-VISA (National Instruments) or lib_usb_win32 driver is required
  %
  %
  % Created    : "2012-10-29 05:28:07 ban"
  % Last Update: "2014-03-28 12:51:39 ban"

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
        %notfound=loadlibrary('admesy_usbtmc.dll','admesy_usbtmc.h','alias','usbtmc');
        notfound=loadlibrary('admesy_usbtmc.dll',@admesy_usbtmc_matlab,'alias','usbtmc');
        if ~isempty(notfound)
          error('library: admesy_usbtmc.dll & admesy_usbtmc.h not found. check input variable.');
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
      if nargin<=2 || isempty(integtime), integtime=20000; end
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
        % (Y,x,y,clip,noise) ?¨ %f,%f,%f,%d,%d\n;
        %
        % The integration time setting can be varied from 0.5ms to 5s.
        % It is specified in ƒÊs. Results from the Brontes-LL colorimeter include a clip and noise
        % indication which indicate whether the measured light is too bright (clip) or too low (noise).
        % When clipping is detected, the resulting colour will not be correct and a lower integration time
        % should be chosen. When noise is detected, a larger integration time should be chosen.

        [dummy,obj.devicehandle]=calllib('usbtmc','usbtmc_write',obj.devicehandle,':meas:YXY',obj.TIME_OUT);
        data_ptr=libpointer('stringPtr',repmat(' ',1,255));
        [dummy,obj.devicehandle,measured]=calllib('usbtmc','usbtmc_read',obj.devicehandle,data_ptr,obj.TIME_OUT);
        clear data_ptr;

        if ~isempty(measured)
          val=sscanf(measured,'%f,%f,%f,%d,%d\n');
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
          warning('measuring failed. check cable connection'); %#ok
          qq=1; Y=[]; x=[]; y=[];
        end
      end
    end

    % write command to Brontes-LL through USB connection
    function [obj,command]=write(obj,command)
      calllib('usbtmc','usbtmc_write',obj.devicehandle,command,obj.TIME_OUT);
    end

    % read results etc from Brontes-LL through USB connection
    function [obj,results]=read(obj)
      data_ptr=libpointer('stringPtr',repmat(' ',1,255));
      [dummy,obj.devicehandle,results]=calllib('usbtmc','usbtmc_read',obj.devicehandle,data_ptr,obj.TIME_OUT);
      clear data_ptr;
    end

  end % methods

end % classdef brontesLL
