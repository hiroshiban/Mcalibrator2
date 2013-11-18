classdef pr650
  % a class to manipulate PhotoResearch PR-650 from MATLAB through a serial port connection
  %
  % Created    : "2012-04-11 09:23:57 ban"
  % Last Update: "2013-05-14 22:17:55 ban"

  properties (Hidden) %(SetAccess = protected)
    portname='COM1'; % id of serial port to communicate with PR-650
    rscom=[];  % serial port object
  end

  properties
    init_flg=0;
  end

  methods

    % constructor
    function obj=pr650(port_name)
      if nargin>1 && ~isempty(port_name)
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

    % create/open a serial port connection to communicate with PR-650
    function obj=gen_port(obj,port_name)
      if nargin>1 && ~isempty(port_name)
        obj.portname=port_name;
        obj.rscom=serial(obj.portname);
      elseif ~isempty(obj.port_name)
        obj.rscom=serial(obj.portname);
      else
        error('set a name of serial port.');
      end

      set(obj.rscom,'BaudRate',9600,'DataBits',8,'Parity','none');
      set(obj.rscom,'DataBits',8,'Parity','none','StopBits',1,'Timeout',20);

      fopen(obj.rscom);

      % set RTS line low for > 50ms
      fclose(obj.rscom);
      delete(obj.rscom);
      pause(0.1);

      % set RTS line high
      obj.rscom=serial(obj.portname);
      set(obj.rscom,'BaudRate',9600,'DataBits',8,'Parity','none');
      set(obj.rscom,'DataBits',8,'Parity','none','StopBits',1,'Timeout',20);
      fopen(obj.rscom);
      pause(1.0); % > 0.5 secs

      % send a command within 5 seconds.
      fprintf(obj.rscom,'S\n');

      obj.init_flg=1;
    end

    % reset a serial port connection
    function obj=reset_port(obj)
      fclose(obj.rscom);
      delete(obj.rscom);
      obj.rscom=[];
      obj.init_flg=0;
    end

    % initialize PR-650
    function [obj,check,integtime]=initialize(obj,integtime)

      if isempty(obj.rscom), error('serial connection has not been established. run gen_port first.'); end

      % NOTICE!!
      %
      % You must run the command below this line and send some commands, for example ASCII cord 'S'(initialize) or 'B'(backlight)
      % to the PR-650 within *** 5 seconds *** !
      % Otherwise, the PR-650 will be initialized and start with a normal measuring mode.

      % Set Up Measurement Parameters.
      if nargin==2 && ~isempty(obj,integtime)
        fprintf(obj.rscom, 'S1,,,,,%d,,1\n',integtime);
      else
        fprintf(obj.rscom, 'S1,,,,,1000,,1\n');
      end

      % Format -S [<1st acc number>],(integer 01-12) default  = 01 (Standard Objective Lens, typically MS-75)
      %           [<2nd acc number>],(integer 02-12)
      %           [<3rd acc number>],(integer 02-12)
      %           [<4th acc number>],(integer 02-12)
      %           [<nom sync frequency>],(integer 1(Condition Used Last F Command), or 40-250Hz)
      %           [<intergration time>],(integer 10-6000 milli seconds)
      %           [<avg cnt>],(integer 01-99) default = 01
      %           [<units type>]<CR> (character) defaut = 0   0:(English) - footLamberts or footcandles, 1:(metric SI) - cd*m^-2 or lux

      % Checking setting parameters.
      fprintf(obj.rscom,'D201\n'); % fermatted output returned from the PR-650 following 'S' command line.

      % Command D201 returned by the PR-650 whenever the 'S' command is sent.
      % Format 201    pp<CR><LF>
      %               pp : 00 = ok
      %                    01-08 number of parameter in 'S' command that is invalid.
      %                    50 either: No Primary accessory specified, or more than one Primary Accesory was
      %                               specified or the first accessory is not a Primary Accesory.

      fscanf(obj.rscom); % to delete extra character.;
      check=fscanf(obj.rscom);
      check=str2num(check); %#ok

      %fwrite(obj.rscom, 'B'); % Set Backlight Level

      % Format -B[M]<CR>
      %   M = 0 backlight off
      %       1 backlight on minimum brightness
      %       2 backlight on medium brightness
      %       3 backlight on maximum brightness
      %   default = 0 (backlight off)
      %   Response Code = 101

      %fprintf(obj.rscom, 'E'); % Echo Command

      % Format -E<CR>
      %   Response Code = none
      %   All characters sent to the PR-650 are echoed back to the host computer or terminal
      %   after an 'E' is sent. There is NO method of returning to a non-echo(half duplex)
      %   state short of a reset. When the PR-650 is ready to receive a command the ">" character
      %   is sent as a prompt.
      %
      % NOTICE!! It is recommended the user not to send 'E' command from an application
      %          program, since it then becoms necessary to receive characters echoed from
      %          the PR-650.
    end

    % measure CIE1931 xyY of the target
    function [qq,Y,x,y,obj]=measure(obj,integtime)

      if isempty(obj.rscom), error('serial connection has not been established. run gen_port first.'); end
      if nargin<2 || isempty(integtime), integtime=500; end

      % set integration time
      fprintf(obj.rscom, 'S1,,,,,%d,,1\n',integtime); % \n -(in matlab)-> CR/LF

      % Measure Light Under Conditions defined by the 'S' command line.
      fprintf(obj.rscom, 'M1\n');
      pause((integtime+200)/1000);

      % Format -M [<Response Code>]<CR> (integer 01-98)
      %   Default Response Code = 01 ()
      %   For this version, use Response Codes 1-6 and 19 with the 'M' command. If using response code 19,
      %   the application program must be ready to accept the binary structure.

      % clear buffer
      while obj.rscom.BytesAvailable>0, fscanf(obj.rscom); end

      % get the result
      fprintf(obj.rscom,'D1\n');

      % Format -D<Response Code><CR>
      %   Allowable Response Codes - ALL
      %   Use this command to retrieve data from the PR-650. This enables the programmer to see several data
      %   reports from a single measurement. If the response code specifies measurement data, that data is
      %   taken from the last measurement proformed by the PR- 650.
      %
      % NOTICE!! The 'D' Command does not initiate measurements.
      %
      % For Users
      %   Response Code 1 should be used
      %       Luminance and 1931 CIE x and y. Returned after sending the 'M' or 'D' command and
      %       the character '1'(M1 or M2) to the PR-650.

      % store the data
      results=fscanf(obj.rscom);
      dresults=sscanf(results,'%d,%d,%e,%f,%f');
      qq = dresults(1);
      Y=dresults(3);
      x=dresults(4);
      y=dresults(5);

      % if the quality of measurement is fine, exit
      if qq==0, return; end

      % retry based on quality
      numretry=1; qq=1;
      while numretry<=5 && qq>0
        numretry=numretry+1;
        if qq==19 % too high
          integtime=max(round(integtime/2),50);
        elseif qq==18 % too low
          integtime=min(integtime*2,6000);
        else
          % integtime=integtime;
        end

        fprintf(obj.rscom, 'S1,,,,,%d,,1\n',integtime); % \n -(in matlab)-> CR/LF
        fprintf(obj.rscom, 'M1\n');
        pause((integtime+200)/1000);
        while obj.rscom.BytesAvailable>0, fscanf(obj.rscom); end
        fprintf(obj.rscom,'D1\n');
        results=fscanf(obj.rscom);
        dresults=sscanf(results,'%d,%d,%e,%f,%f');
        qq = dresults(1);
        Y=dresults(3);
        x=dresults(4);
        y=dresults(5);
      end

      % NOTICE!!  These parameters work on only when the Response Code is 01.
      %           You should set the code 01 in sending 'M (measure)'
      %           command to the PR-650.     i.e. fprintf(obj.rscom, 'M01')
      %
      % Response Code 1
      %           Luminance and 1931 CIE x and y. Returned after sending the 'M' or 'D'
      %           command and the character '1' (M1 or D1) to the PR-650.
      %
      % Format       : qq,U,Y.YYYEsee,.xxxx,.yyyy<CR><LF>
      % qq           : Measurement quality code (00 = O.K.)
      % U            : 0 for luminance   (units = footLamberts or cd*m^-2)
      %                1 for illuminance (units = footcandles or lux)
      %                2 Uncalibrated
      % Y.YYYEsee    : 1931 CIE Y (units indicated by U)
      % .xxxx        : 1931 CIE x
      % .yyyy        : 1931 CIE y

      %if(qq ~= 0)&(qq ~= 1)
      %    Y=x=y=nan;
      %    return;
      %end
    end

    % measure CIE1931 xyY and spectrum of the target
    function [qq,U,YY,xx,yy,wavelength,spectIntensity]=measurespectrum(obj)
      fprintf(obj.rscom,'D120\n');

      if isempty(obj.rscom), error('serial connection has not been established. run gen_serial first.'); end

      % Format -D<Response Code><CR>
      %   Allowable Response Codes - ALL
      %   Use this command to retrieve data from the PR-650. This enables the programmer to see several data
      %   reports from a single measurement. If the response code specifies measurement data, that data is
      %   taken from the last measurement proformed by the PR- 650.
      %
      % NOTICE!! The 'D' Command does not initiate measurements.
      %
      % Response Code = 120
      %   Spectral range of this instrument (for the PR-650, 380-780nm).
      %   Returned when the 'D120' command is sent to the PR-650.
      %
      % Format    : pppp,bbb.b,ffff.,wwww.,iii.<CR><LF>
      % pppp      : Number of spectral data points
      % bbb.b     : Bandwidth of ths instrument in nm
      % ffff.     : Wavelength of first spectral data point in nanometers (380 nm)
      % wwww.     : Wavelength of last spectral data point in nanometers (780 nm)
      % iii.      : width of each spectral data point in nm (4nm)

      parameters = fscanf(obj.rscom);
      datapoints = str2num(parameters(1:4)); %#ok
      bandwidth = str2num(parameters(6:10)); %#ok
      startvalue = str2num(parameters(12:15)); %#ok
      endvalue = str2num(parameters(18:21)); %#ok
      inter = str2num(parameters(24:27)); %#ok
      wavelength = zeros(1,(endvalue-startvalue)/inter+1);
      spectIntensity = zeros(1,(endvalue-startvalue)/inter+1);
      fscanf(obj.rscom); % to delete extra character.

      fprintf(obj.rscom,'M5\n'); % Measure Light Under Conditions defined by the 'S' command line.

      % Format -M [<Response Code>]<CR> (integer 01-98)
      %   Default Response Code = 01 ()
      %   For this version, use Response Codes 1-6 and 19 with the 'M' command. If using response code 19,
      %   the application program must be ready to accept the binary structure.

      % Response Code = 05
      %   Radiometric(spectral) data. Returned after sending the 'M' or 'D' command and the charcter '5'
      %   as 'M5' or 'D5' to the PR-650.
      %
      % Format    : qq,U<CR>i.iiiEsee<CR><LF>
      %             wwww.,r.rrrEsee<CR><LF>
      %             wwww.,r.rrrEsee<CR><LF>
      % qq        : Measurement quality code (00 = O.K.)
      % U         : 0 for spectral radiance   (units = W * m^-2 * sr^-1 * nm^-1)
      %             1 for spectral irradiance (units = W * m^-2 * nm^-1)
      %             2 Uncalibrated
      % i.iiiEsee : Integrated Intensity (total area under spectral curve) in units specified by 'U'
      % wwww.     : Wavelength in nanometers. There will be one line with wavelength and corrected
      %             spectral intensity for each data point, delimited by a comma.
      %             Response code 120 provides the starting and ending wavelengths and increment.
      % r.rrrEsee : Spectral intensity in units indicated by 'U'

      fprintf(obj.rscom,'D5\n'); % Output Data to the Host.

      % Format -D<Response Code><CR>
      %   Allowable Response Codes - ALL
      %   Use this command to retrieve data from the PR-650. This enables the programmer to see several data
      %   reports from a single measurement. If the response code specifies measurement data, that data is
      %   taken from the last measurement proformed by the PR- 650.
      %
      % NOTICE!! The 'D' Command does not initiate measurements.
      %
      % Response Code = 05
      %   Radiometric(spectral) data. Returned after sending the 'M' or 'D' command and the charcter '5'
      %   as 'M5' or 'D5' to the PR-650.
      %
      % Format    : qq,U<CR>i.iiiEsee<CR><LF>
      %             wwww.,r.rrrEsee<CR><LF>
      %             wwww.,r.rrrEsee<CR><LF>
      % qq        : Measurement quality code (00 = O.K.)
      % U         : 0 for spectral radiance   (units = W * m^-2 * sr^-1 * nm^-1)
      %             1 for spectral irradiance (units = W * m^-2 * nm^-1)
      %             2 Uncalibrated
      % i.iiiEsee : Integrated Intensity (total area under spectral curve) in units specified by 'U'
      % wwww.     : Wavelength in nanometers. There will be one line with wavelength and corrected
      %             spectral intensity for each data point, delimited by a comma.
      %             Response code 120 provides the starting and ending wavelengths and increment.
      % r.rrrEsee : Spectral intensity in units indicated by 'U'

      %% OBSOLETE
      %results=fscanf(obj.rscom);
      %qq = str2num(results(1:2));
      %U = str2num(results(4));
      %results=fscanf(obj.rscom);
      %IntegIntensity = str2num(results(1:8));

      % NEW
      results=fscanf(obj.rscom);
      results2=fscanf(obj.rscom);
      dresults=sscanf(results, '%d,%d');
      qq = dresults(1); %#ok
      U = dresults(2);
      IntegIntensity = sscanf(results2,'%e'); %#ok

      %% OBSOLETE
      %for i = 1:1:(endvalue-startvalue)/inter+1
      %    results=fscanf(obj.rscom);
      %    wavelength(i) = str2num(results(1:4));
      %    spectIntensity(i) = str2num(results(7:15));
      %end

      % NEW  Apr. 21 2004
      for i = 1:1:(endvalue-startvalue)/inter+1
          results=fscanf(obj.rscom);
          dresults=sscanf(results,'%f,%e');
          wavelength(i) = dresults(1);
          spectIntensity(i) = dresults(2);
      end

      % NOTICE!!  These parameters work on only when the Response Code is 05.
      %           You should set the code 05 in sending 'M (measure)'
      %           command to the PR-650.     i.e. fprintf(obj.rscom, 'M5')

      %if(qq ~= 0)&(qq ~= 1)
      %    wavelength=spectIntensity=nan;
      %    break;
      %end

      fprintf(obj.rscom, 'M1\n'); % Measure Light Under Conditions defined by the 'S' command line.

      % Format -M [<Response Code>]<CR> (integer 01-98)
      %   Default Response Code = 01 ()
      %   For this version, use Response Codes 1-6 and 19 with the 'M' command. If using response code 19,
      %   the application program must be ready to accept the binary structure.

      fscanf(obj.rscom); % to delete extra characters
      fscanf(obj.rscom); % to delete extra characters
      for i = 1:1:(endvalue-startvalue)/inter+1, fscanf(obj.rscom); end % to delete extra characters
      fprintf(obj.rscom, 'D1\n'); % Output Data to the Host.

      % Format -D<Response Code><CR>
      %   Allowable Response Codes - ALL
      %   Use this command to retrieve data from the PR-650. This enables the programmer to see several data
      %   reports from a single measurement. If the response code specifies measurement data, that data is
      %   taken from the last measurement proformed by the PR- 650.
      %
      % NOTICE!! The 'D' Command does not initiate measurements.
      %
      % For Users
      %   Response Code 1 should be used
      %       Luminance and 1931 CIE x and y. Returned after sending the 'M' or 'D' command and
      %       the character '1'(M1 or M2) to the PR-650.

      % OBSOLETE
      results=fscanf(obj.rscom);
      qq = str2num(results(1:2)); %#ok
      YY=str2num(results(6:14)); %#ok
      xx=str2num(results(16:20)); %#ok
      yy=str2num(results(22:26)); %#ok
      debris=fscanf(obj.rscom); %#ok

      %% NEW Apr. 21 2004
      %results=fscanf(obj.rscom);
      %dresults=sscanf(results,'%d,%d,%e,%f,%f');
      %qq = dresults(1);
      %YY = dresutls(3);
      %xx = dresults(4);
      %yy = dresults(5);
      %debris=fscanf(obj.rscom);

      % NOTICE!!  These parameters work on only when the Response Code is 01.
      %           You should set the code 01 in sending 'M (measure)'
      %           command to the PR-650.     i.e. fprintf(obj.rscom, 'M01')
      %
      % Response Code 1
      %           Luminance and 1931 CIE x and y. Returned after sending the 'M' or 'D'
      %           command and the character '1' (M1 or D1) to the PR-650.
      %
      % Format       : qq,U,Y.YYYEsee,.xxxx,.yyyy<CR><LF>
      % qq           : Measurement quality code (00 = O.K.)
      % U            : 0 for luminance   (units = footLamberts or cd*m^-2)
      %                1 for illuminance (units = footcandles or lux)
      %                2 Uncalibrated
      % Y.YYYEsee    : 1931 CIE Y (units indicated by U)
      % .xxxx        : 1931 CIE x
      % .yyyy        : 1931 CIE y

      %if(qq ~= 0)&(qq ~= 1)
      %    YY=xx=yynan;
      %    return;
      %end
    end

  end % methods

end % classdef pr650
