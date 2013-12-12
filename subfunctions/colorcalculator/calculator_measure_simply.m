function calculator_measure_simply(hObject, eventdata, handles)

% A wrapper function of MeasureCIE1931xyY to call it from Mcalibrator2 with GUI-based data handling.
% function calculator_measure_simply(hObject, eventdata, handles)
%
% This function simply measures CIE1931 xyY values estimated by the standard
% linear transformation using phopher tristimulus values.
% This function also handles and communicates data listed in Mcalibrator2 GUI window.
%
% [input]
% All input variables are objects of Mcalibrator2
% hObject   : handle to figure
% eventdata : reserved - to be defined in a future version of MATLAB
% handles   : structure with handles and user data (see GUIDATA)
%
% [output]
% no output variable
%
%
% Created    : "2012-05-29 04:09:02 ban"
% Last Update: "2013-12-13 10:07:38 ban"

global config;
global colorimeterhandler;
global displayhandler;
global phosphors;

set(handles.information_uipanel,'Title','information');

% get RGB values to be measured
if isempty(get(handles.RGB_edit,'String'))
  set(handles.information_text,'String','no RGB values found. Set the values you want first.');
  return
end

myrgb=getDataFromStr(get(handles.RGB_edit,'String'));

% convert LUT IDs to RGB values
if get(handles.use_LUT_radiobutton,'Value')
  lut=LoadLUTs();
  if isempty(lut), set(handles.information_text,'String','can not load RGB LUTs. Generate them first.'); PlaySound(0); return; end

  % get rgb values corresponding to the target LUT IDs
  for nn=1:1:size(myrgb,1), myrgb(nn,:)=[lut(myrgb(nn,1),1),lut(myrgb(nn,2),2),lut(myrgb(nn,3),3)]; end
end

% initialize color window
fig_id=displayhandler([255,255,255],1); pause(0.2);

% measurement
mesxyY=zeros(size(myrgb,1),3);
for ii=1:1:size(myrgb,1)
  set(handles.information_text,'String',sprintf('Measuring CIE 1931 xyY for #data %d...',ii));
  [mesxyY(ii,3),mesxyY(ii,1),mesxyY(ii,2),displayhandler,colorimeterhandler]=...
        MeasureCIE1931xyY(displayhandler,colorimeterhandler,myrgb(ii,:),1,fig_id);
  set(handles.information_text,'String',sprintf('Measuring CIE 1931 xyY for #data %d...Done.',ii));
end
displayhandler(-999,1,fig_id);

% set measured data to results_xyY_edit
str_mesxyY=[];
for ii=1:1:size(mesxyY,1)
  str_mesxyY=[str_mesxyY,num2str(mesxyY(ii,1)),',',num2str(mesxyY(ii,2)),',',num2str(mesxyY(ii,3)),';']; %#ok
end
set(handles.results_xyY_edit,'String',str_mesxyY);
set(handles.results_RGB_edit,'String',get(handles.RGB_edit,'String')); % set RGB value asis

% plotting
rawxyY=getDataFromStr(get(handles.xyY_edit,'String'));
set(handles.information_text,'String','Plotting measured data on the CIE1931 diagram...');
axes(handles.color_figure); %#ok
hold off;
PlotCIE1931xy((rawxyY(:,1:2))',phosphors,-1,1,1,1);
PlotCIE1931xy((mesxyY(:,1:2))',phosphors,0,1,1,0);
hold off;

set(handles.information_text,'String','Plotting measured data on the CIE1931 diagram...Done.');

return
