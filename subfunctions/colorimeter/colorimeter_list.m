function colorimeters=colorimeter_list()

% A list of colorimeter/photometer used in Mcalibrator2.
% function colorimeters=colorimeter_list()
%
% Mcalibrator2, colorimeter_list
%
% The list described here is used for initializing
% apparatus_popupbutton object.
%
% If you want to add your own apparatus,
% add {'apparatus_name_you_use','object_name_to_manipulate_the_apparatus',port_type}
% into the list.
%
% [note 1]
% here, port_tyep is 0/1 value to determine how the apparatus is connected.
% 0 : serial port
% 1 : USB port, communicated via DLL, lib_usb, Psychtoolbox subfunctions etc.
%
% [note 2]
% object should be a class containing the properties/functions listed below.
%
% properties (Hidden)
%   portname % name of serial/USB port
%   rscom    % serial/USB port object
% properties
%   init_flg
% methods
%   gen_port
%   reset_port
%   initialize
%   measure
%
% For details, please see pr650/cs100a (for serial connection) or brontesLL/colorcal (for USB connection) objects.
%
%
% Created    : "2012-04-14 04:09:02 ban"
% Last Update: "2023-12-12 18:06:31 ban"

colorimeters{1}={'Photo Research PR-650','pr650',0};
colorimeters{2}={'Photo Research PR-655 (not tested, PTB3 is required)','pr655',0};
colorimeters{3}={'KONICA-MINOLTA CS-100A','cs100a',0};
colorimeters{4}={'KONICA-MINOLTA CS-150/160 (wrapper)','cs150_160',1};
colorimeters{5}={'Admesy Brontes-LL (64bit)','brontesLL',1};
colorimeters{6}={'Admesy Brontes-LL (32bit)','brontesLL32',1};
colorimeters{7}={'Cambridge Research Systems ColorCAL2 Win-USB','colorcal',1};
%colorimeters{8}={'Cambridge Research Systems ColorCAL2 (PTB, not tested)','colorcal2',1};
colorimeters{8}={'Cambridge Research Systems ColorCAL CDC (Virtual Port)','colorcalcdc',0};
colorimeters{9}={'Cambridge Research Systems OptiCal (not tested)','optical',0};
colorimeters{10}={'International Light IL1700','il1700',0};
colorimeters{11}={'Dummy Colorimeter (for Debug)','dummy_colorimeter',0};

return
