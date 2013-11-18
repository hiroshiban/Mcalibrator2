classdef colorcal2
  % a class to manipulate Cambridge Research Systems ColorCal2 from MATLAB through a USB connection
  %
  % [NOTE]
  % requires Psychtoolbox to communicate ColorCal through a USB port.
  % Especially,
  % 1. libsub-1.0.dll (should be located somewhere in pathes)
  % 2. MATLAB functions in Psychtoolbox --- ColorCal2, LoadPsychHID, PsychHID
  % are required for this class
  %
  %
  % Created    : "2012-04-11 09:23:57 ban"
  % Last Update: "2012-04-17 09:38:27 ban"

  properties (Hidden)
    portname=6; % id of USB port to communicate with ColorCal2
    rscom=[];  % serial port object
  end

  properties
    init_flg=0;
  end

  methods

    % constructor
    function obj=colorcal2(port_name)
      if nargin==1 && ~isempty(port_name)
        obj.portname=port_name;
      else
        obj.portname=1;
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

    % create/open a serial port connection to communicate with CS-100A
    function info_str=gen_port(obj,port_name)
      % "port_name" is a dummy variable to match the function format with the other device object.

      if ~exist('PsychHID','file')
        error('Psychtoolbox is required to communicate with ColorCal2. Install it first.');
      end
      info_str=ColorCal2('DeviceInfo');
      obj.init_flg=1;
    end

    % reset a serial port connection
    function obj=reset_port(obj)
      obj.init_flg=0;
    end

    % initialize ColorCal2
    function check=initialize(obj,integtime)
      % "integtime" is a dummy variable to match the function format with the other device object.

      %ColorCal2('ZeroCalibration');
      check=0;
    end

    function obj=zerocalibration(obj)
      ColorCal2('ZeroCalibration');
    end

    % measure CIE1931 xyY of the target
    function [qq,Y,x,y]=measure(obj)
      s=ColorCal2('MeasureXYZ');
      xyY=XYZ2xyY([s.x;s.y;s.Y]);
      Y=xyY(3);
      x=xyY(1);
      y=xyY(2);
      qq=0;
    end

  end % methods

end % classdef pr650
