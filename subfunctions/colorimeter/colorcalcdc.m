classdef colorcalcdc
  % a class to manipulate Cambridge Research Systems ColorCal from MATLAB through a virtual port (CDC) connection
  %
  % Created    : "2015-06-25 16:49:54 ban"
  % Last Update: "2015-07-02 10:34:35 ban"
  %
  % [example]
  % >> cc=colorcalcdc;
  % >> cc=cc.gen_port();
  % >> cc=cc.initialize();
  % >> cc=cc.measure();
  %
  % [methods]
  % colorcal=colorcal.gen_port('PORT')             : generate USB port to communicate with ColorCAL
  % colorcal=colorcal.initialize(integration_time) : initialize measurement parameters
  % colorcal=colorcal.reset_port()                 : reset USB port connection
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
    zero_init_flg=0; % a flag to specify whether the zero-calibration is done or not
    corr_matrix_flg=0; % a flag to specify whether the correction matrix is obtained or not
  end

  properties
    init_flg=0;
  end

  methods

    % constructor
    function obj=colorcalcdc(port_name)
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

      obj.init_flg=1;
    end

    % reset a virtual serial connection
    function obj=reset_port(obj)
      fclose(obj.rscom);
      delete(obj.rscom);
      obj.rscom=[];
      obj.init_flg=0;
      obj.zero_init_flg=0;
      obj.corr_matrix_flg=0;
    end

    % initialize ColorCal
    function [obj,check,integtime]=initialize(obj,integtime)
      % "integtime" is a dummy variable to match the function format with the other device object.
      if nargin<=2 || isempty(integtime), integtime=0; end

      if ~obj.init_flg
        disp('generate a virtual port to communicate with ColorCal first.');
        check=0;
        % do nothing
      else

        if obj.zero_init_flg && obj.corr_matrix_flg
          %disp('initizalization was already done. if you want to run again, reset the port first.');
          check=0;
        else

          try

            % ========================================
            % initialization step 1: run zero-level calibration
            % ========================================

            counter=0;
            while ~obj.zero_init_flg && counter<10
              counter=counter+1;

              % commands are passed to the ColorCAL II as though they were being written to a text file, using fprintf. The command UZC will read
              % current light levels and store them in a zero correction array. All subsequent light readings have this value subtracted from them before
              % being returned to the host. Note the '13' represents the terminator character. 13 represents a carriage return and should be included at
              % the end of every command to indicate when a command is finished.
              fprintf(obj.rscom, ['UZC',13]);
              fscanf(obj.rscom); % to remove a blank character at the start of each line by default

              % get the actual data
              dataLine=deblank(fscanf(obj.rscom));
              if ~isempty(strfind(dataLine,'OK00'));
                % calibration is successful.
                disp('Zero-calibration successful.');
                obj.zero_init_flg=1;
              else % ~isempty(strfind(dataLine,'ER11'))
                warning('ERROR during zero-calibration. Perhaps too much residual light. Ensure sensor is covered');
              end

            end % while ~obj.zero_init_flg

            if ~obj.zero_init_flg
              warning('FAILED zero-calibration. Reset the port and initialize ColorCAL again.');
            end

            % ========================================
            % initialization step 2: get the correction matrix for converting the measured values to XYZ tristimulus values
            % ========================================

            counter=0;
            while ~obj.corr_matrix_flg && counter<10
              counter=counter+1;
              cmtx_err=false;

              for ii=1:1:3 % cycle through the 3 rows of the correction matrix.
                % Commands are passed to the ColorCAL II as though they were being written to a text file, using fprintf. The commands 'r01', 'r02'
                % and 'r03' will return the 1st, 2nd and 3rd rows of the correction matrix respectively. Note the '13' represents the terminator
                % character. 13 represents a carriage return and should be included at the end of every command to indicate when a command is finished.
                fprintf(obj.rscom,['r0',num2str(ii),13]);
                fscanf(obj.rscom); % to remove a blank character at the start of each line by default

                % To read the returned data
                dataLine=deblank(fscanf(obj.rscom));
                sidx=strfind(dataLine,'OK00,');
                if ~isempty(sidx)
                  dataLine=dataLine(sidx:end); % required to skip the blank character(s) in the head of the string
                  obj.corrmatrix(ii,1)=str2num(dataLine(6:10));
                  obj.corrmatrix(ii,2)=str2num(dataLine(12:16));
                  obj.corrmatrix(ii,3)=str2num(dataLine(18:22));
                else
                  cmtx_err=true;
                end
              end % for ii = 1:1:3

              if isempty(obj.corrmatrix) || cmtx_err
                warning('ERROR getting the correction matrix. Retrying...');
                continue;
              end

              % Values returned by the ColorCAL II are 10000 times larger than their actual value. Also, negative values have a further 50000 added to them.
              % These transformations need to be reversed to get the actual values. The positions of myCorrectionMatrix with values greater than 50000 have
              % 50000 subtracted from them and then converted to their equivalent negative value.
              obj.corrmatrix(obj.corrmatrix>50000)=0-(obj.corrmatrix(obj.corrmatrix>50000)-50000);
              obj.corrmatrix=obj.corrmatrix./10000; % All values are then divided by 10000 to give actual values.
              obj.corr_matrix_flg=1;
              disp('Correction-matrix was successfully obtained.');
            end % if ~obj.corr_matrix_flg

            if obj.corr_matrix_flg
              check=0;
            else
              warning('FAILED getting the correction matrix. Reset the port and initialize ColorCAL again.');
              check=1;
            end

          catch
            warning('Initialization error. check device connection and try again');
            check=1;
          end % try

        end % if obj.zero_init_flg & obj.corr_matrix_flg
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
        fscanf(obj.rscom); % to remove a blank character at the start of each line by default

        % To read the returned data, use fscanf, as though reading from a text file.
        dataLine=deblank(fscanf(obj.rscom));
        sidx=strfind(dataLine,'OK00,');
        if ~isempty(sidx)
          dataLine=dataLine(sidx:end);
          meas_vals=[str2double(dataLine(6:11)),str2double(dataLine(13:18)),str2double(dataLine(20:25))];
          qq=0;
        else % strcmp(dataLine(1:5),'ERXX,')
          qq=1;
        end
      end % while qq~=0 && counter<5

      % The returned values need to be multiplied by the ColorCAL II's individual calibration matrix, as retrieved earlier.
      % This will convert the three values into CIE XYZ.
      XYZ=obj.corrmatrix*meas_vals';

      % Convert recorded XYZ into CIE1931 xyY values
      denom=sum(XYZ,1);
      xyY=[XYZ(1:2,:)./denom([1,1]',:); XYZ(2,:)];
      x=xyY(1); y=xyY(2); Y=xyY(3);
    end

  end % methods

end % classdef colorcalcdc
