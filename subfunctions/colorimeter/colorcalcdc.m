classdef colorcalcdc
  % a class to manipulate Cambridge Research Systems ColorCal from MATLAB through a virtual port (CDC) connection
  %
  % Created    : "2015-06-25 16:49:54 ban"
  % Last Update: "2015-06-25 21:23:15 ban"
  %
  % [example]
  % >> cc=colorcal;
  % >> cc=cc.gen_port();
  % >> cc=cc.initialize();
  % >> cc=cc.measure();
  %
  % [methods]
  % colorcal=colorcal.gen_port('PORT')             : generate USB port to communicate with ColorCAL
  % colorcal=colorcal.initialize(integration_time) : initialize measurement parameters
  % colorcal=colorcal.reset_port()                 : reset USB port connection
  % colorcal=colorcal.autocalibrate()              : calibrate ColorCAL automatically
  % [qq,Y,x,y,colorcal]=colorcal.measure(integration_time) : measure CIE1931 xyY
  %
  % [NOTE]
  % requires ColorCAL driver, crsltd_usb_cdc_acm.cat and crsltd_usb_cdc_acm.inf distributed by Cambridge Research Systems.
  %
  % [reference]
  % demoColorCALIICDC.m by C.Arnold Dec 2011, destributed by Cambridge Research Systems.

  properties (Hidden) %(SetAccess = protected);
    portname='COM1'; % id of the virtual serial port connected to ColorCal
    rscom=[];  % serial port object
    corrmatrix=[]; % a correction matrix, required for converting measured valus to XYZ tristimulus values.
  end

  properties
    init_flg=0;
  end

  methods

    % constructor
    function obj=colorcal(port_name)
      if nargin==1 && ~isempty(port_name)
        obj.portname=port_name;
      end
    end

    % destructor
    function obj=delete(obj)
      if ~isempty(obj.rscom)
        fclose(obj.rscom);
        delete(obj.rscom);
        obj.rscom=[];
        obj.init_flg=0;
      end
    end

    % create/open a virtual serial port connection to communicate with ColorCAL
    function obj=gen_port(obj,port_name)

      % Use the 'serial' function to assign a handle to the port ColorCAL II is
      % connected to in CDC mode. This handle (s1 in the current example) will
      % then be used to communicate with the chosen port).
      if nargin>1 && ~isempty(port_name)
        obj.portname=port_name;
        obj.rscom=serial(obj.portname);
      elseif ~isempty(obj.portname)
        obj.rscom=serial(obj.portname);
      else
        error('set a name of serial port.');
      end

      % Open the ColorCAL II port so that it is open to be communicated with.
      % Communication with the ColorCAL II occurs as though it were a text file.
      % Therefore to open it, use fopen.
      fopen(obj.rscom);
      %set(obj.rscom,'DataBits',7,'BaudRate',4800,'Parity','even','StopBits',2,'Terminator','CR'); % not sure which values should be taken. have to check the manual...

      % % NEW for MATLAB R14
      % % After initializing the serial port using FOPEN,
      % % you should set the RTS and DTR pins to low using the following code:
      % set (obj.rscom, 'DataTerminalReady' ,'off') ;
      % set (obj.rscom, 'RequestToSend' ,'off') ;
      % % and pause for some msec
      % pause(0.3);
      %
      % % When the RTS and DTR pins are subsequently set high at any time using the following code,
      % % the voltage at the pins will be as expected:
      % set (obj.rscom, 'DataTerminalReady' ,'on') ;
      % set (obj.rscom, 'RequestToSend' ,'on') ;

      obj.init_flg=1;
    end

    % reset a virtual serial connection
    function obj=reset_port(obj)
      fclose(obj.rscom);
      delete(obj.rscom);
      obj.rscom=[];
      obj.init_flg=0;
    end

    % initialize ColorCal
    function [obj,check,integtime]=initialize(obj,integtime)
      % "integtime" is a dummy variable to match the function format with the other device object.
      if nargin<=2 || isempty(integtime), integtime=0; end

      if obj.init_flg~=1
        disp('generate a virtual port to communicate with ColorCal first.');
        check=0;
        % do nothing
      else

        % ========================================
        % initialization step 1: run zero-level calibration
        % ========================================

        calibrate_ok=0;
        while ~calibrate_ok

          % Commands are passed to the ColorCAL II as though they were being written to a text file, using fprintf. The command UZC will read
          % current light levels and store them in a zero correction array. All subsequent light readings have this value subtracted from them before
          % being returned to the host. Note the '13' represents the terminator character. 13 represents a carriage return and should be included at
          % the end of every command to indicate when a command is finished.
          fprintf(obj.rscom, ['UZC',13]);

          % This command returns a blank character at the start of each line by default that can
          % confuse efforts to read the values. Therefore use fscanf once to remove this character.
          fscanf(obj.rscom);

          % To read the returned data, use fscanf, as though reading from a text file
          dataLine = fscanf(obj.rscom);

          % The expected returned messag if successful is 'OKOO' or if an error, 'ER11'. In case of any additional blank characters either side of
          % these messages, search through each character until either an O or an E is found so that the start of the relevant message can be determined.
          for ii=1:1:length(dataLine)

            % Once either an O or an E is found, the start of the relevant information is the current character
            % positiong while the end is 3 characters further (as each possible message is 4 characters in total).
            if dataLine(kk)=='O' || dataLine(kk)=='E'
              sp=kk;
              ep=kk+3;
            end
          end

          % the returned message is the characters between the start and end positions
          data_quality=dataLine(sp:ep);

          % if the message is 'OK00', then report a successful calibration.
          if strcmp(data_quality,'OK00')
            % calibration is successful. Changing calibrateSuccess to 1 will break the while loop and allow the script to continue.
            disp('Zero-calibration successful');
            calibrate_ok=1;
          else
            % display warning message.
            warning('ERROR during zero-calibration. Perhaps too much residual light. Ensure sensor is covered');
          end

        end % while ~calibrate_ok

        % ========================================
        % initialization step 2: get the correction matrix for converting the measured values to XYZ tristimulus values
        % ========================================

        for ii=1:1:3 % cycle through the 3 rows of the correction matrix.
          % whichColumn is to indicate the column the current value is to be written to.
          whichColumn=1;

          % Commands are passed to the ColorCAL II as though they were being written to a text file, using fprintf. The commands 'r01', 'r02'
          % and 'r03' will return the 1st, 2nd and 3rd rows of the correction matrix respectively. Note the '13' represents the terminator
          % character. 13 represents a carriage return and should be included at the end of every command to indicate when a command is finished.
          fprintf(obj.rscom,['r0',num2str(ii),13]);

          % This command returns a blank character at the start of each line by default that can confuse efforts to read the values. Therefore
          % use fscanf once to remove this character.
          fscanf(obj.rscom);

          % To read the returned data, use fscanf, as though reading from a text file.
          dataLine=fscanf(obj.rscom);

          % The returned dataLine will be returned as a string of characters in the form of 'OK00, 8053,52040,50642'. Therefore loop through
          % each character until a O is found to be sure of the start position of the data.
          for jj=1:1:length(dataLine)

            % Once an O has been found, assign the start position of the numbers to 5 characters beyond this (i.e. skipping the 'OKOO,').
            if dataLine(jj) == 'O'
              sp=jj+5;
              % A comma (,) indicates the start of a value. Therefore if this is found, the value is the number formed of the next 5 characters.
            elseif dataLine(jj) == ','
              ep=jj+5;

              % Using j to indicate the row position and whichColumn to indicate the column position, convert the 5 characters to
              % a number and assign it to the relevant position.
              obj.corrmatrix(ii,whichColumn)=str2num(dataLine(sp:ep)); %#ok

              % reset myStart to k+6 (the first value of the next number)
              sp=jj+6;

              % Add 1 to the whichColumn value so that the next value will be saved to the correct location.
              whichColumn=whichColumn+1;
            end
          end % for jj=1:1:length(dataLine)
        end % for ii = 1:1:3

        % Values returned by the ColorCAL II are 10000 times larger than their actual value. Also, negative values have a further 50000 added to them.
        % These transformations need to be reversed to get the actual values. The positions of myCorrectionMatrix with values greater than 50000 have
        % 50000 subtracted from them and then converted to their equivalent negative value.
        obj.corrmatrix(obj.corrmatrix>50000)=0-(obj.corrmatrix(obj.corrmatrix>50000)-50000);

        % All values are then divided by 10000 to give actual values.
        obj.corrmatrix=obj.corrmatrix./10000;

        check=0;
      end % if obj.init_flg~=1
    end

    % measure CIE1931 xyY of the target
    function [qq,Y,x,y,obj]=measure(obj,integtime)
      % integtime is a dummy variable to match input variables with the other functions
      if nargin<2 || isempty(integtime)
        integtime=0; %#ok
      end

      qq=1; counter=0;
      while qq~=0 && counter<5
        meas_vals=[];
        counter=counter+1;

        % commands are passed to the ColorCAL II as though they were being written to a text file, using fprintf. The command MES will read current light levels
        % and and return the tri-stimulus value (to 2 decimal places), adjusted by the zero-level calibration values above. Note the '13' represents the terminator
        % character. 13 represents a carriage return and should be included at the end of every command to indicate when a command is finished.
        fprintf(obj.rscom,['MES',13]);

        % This command returns a blank character at the start of each line by default that can confuse efforts to read the values.
        % Therefore use fscanf once to remove this character.
        fscanf(obj.rscom);

        % To read the returned data, use fscanf, as though reading from a text file.
        dataLine=fscanf(obj.rscom);

        % The returned dataLine will be returned as a string of characters in the form of 'OK00,242.85,248.11, 89.05'. In case of additional blank characters
        % before or after the relevant information, loop through each character until a O is found to be sure of the start position of the data.
        for ii=1:1:length(dataLine)

          % Once an O has been found, assign the start position of the numbers to 5 characters beyond this (i.e. skipping th 'OKOO,')
          if dataLine(ii)=='O'
            sp=ii+5;
            qq=0;
            % A comma (,) indicates the start of a value. Therefore if this is found, the value is the number formed of the next 6 characters
          elseif dataLine(ii)==','
            ep=ii+6;

            % Using k to indicate the row position and whichColumn to indicate the column position, convert the 5 characters to a
            % number and assign it to the relevant position.
            meas_vals(whichColumn)=str2num(dataLine(sp:ep)); %#ok

            % reset myStart to k+7 (the first value of the next number)
            sp=ii+7;

            % Add 1 to the whichColumn value so that the next value will be saved to the correct location.
            whichColumn=whichColumn+1;
          end
        end

      end % while qq~=0 && counter<5

      % The returned values need to be multiplied by the ColorCAL II's individual calibration matrix, as retrieved earlier.
      % This will convert the three values into CIE XYZ.
      XYZ=obj.corrmatrix*meas_vals';

      % Convert recorded XYZ into CIE1931 xyY values
      denom=sum(XYZ,1);
      xy=XYZ(1:2,:)./denom([1,1]',:);
      xyY=[xy; XYZ(2,:)];
      x=xyY(1); y=xyY(2); Y=xyY(3);
    end

  end % methods

end % classdef colorcalcdc
