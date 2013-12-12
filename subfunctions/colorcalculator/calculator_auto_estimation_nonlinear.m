function calculator_auto_estimation_nonlinear(hObject, eventdata, handles)

% A wrapper function of AutoColorEstimateNonLinear to call it from Mcalibrator2 with GUI-based data handling.
% function calculator_auto_estimation_nonlinear(hObject, eventdata, handles)
%
% This is a wrapper to AutoColorEstimateNonLinear function.
% Actual estimation is done through that function.
% This function handles and communicates data listed in Mcalibrator2 GUI window.
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
% [note]
% for details of estimation,
% see AutoColorEstimateNonLinear.m in subfunctions/mains directory.
%
%
% Created    : "2012-05-29 04:09:02 ban"
% Last Update: "2013-12-11 17:43:30 ban"

global config;
global colorimeterhandler;
global displayhandler;
global phosphors;
global flares;

set(handles.information_uipanel,'Title','information');
set(handles.information_text,'String','Automatic non-linear estimation of xyY values started...');

% create luminance file format
save_dir=fullfile(config.save_dir,config.date);
save_fname=fullfile(save_dir,sprintf('mcalibrator2_results_%s.mat',config.date));

if isempty(phosphors)
  set(handles.information_text,'String','phosphor chromaticities have not acquired yet. Measure them first.');
  return
end

% get xyY values you want
if isempty(get(handles.xyY_edit,'String'))
  set(handles.information_text,'String','no RGB values found. Set the values you want first.');
  return
end

myxyY=(getDataFromStr(get(handles.xyY_edit,'String')))';
rawxyY=myxyY;

% flare correction
if config.flare_correction
  flare_xyY=flares;%repmat(flares,1,size(myxyY,2));
  flare_XYZ=xyY2XYZ(flares);
else
  flare_xyY=[];
  flare_XYZ=zeros(3,1);
end
myrgb=xyY2RGB(myxyY,phosphors,flare_xyY);
myxyY=RGB2xyY(myrgb,phosphors,flare_xyY);
myphosphors=XYZ2xyY( xyY2XYZ(phosphors)-repmat(flare_XYZ,1,3) );

% load LUTs if use_LUT (radiobutton) is set
if get(handles.use_LUT_radiobutton,'Value')
  lut=LoadLUTs();
  if isempty(lut), set(handles.information_text,'String','can not load RGB LUTs. Generate them first.'); PlaySound(0); return; end
else
  lut=[];
end

% non-linear estimations of RGB values using a simplex-search method (direct search, having a local-minimum problem).
% here, estimation is done in XYZ space, not in xyY, to make the estimation stable.
% if we estimate in xyY space, the results will be distorted as Y is too large compared with the other values
%options=optimset('Display','iter','MaxFunEvals',250,'TolFun',0.1,'TolX',5e-2,'MaxIter',50);
options=optimset('Display','iter','MaxFunEvals',250,'TolFun',0.1,'TolX',1e-2,'MaxIter',50,'DiffMinChange',1e-3);
nonlinear_estimate=AutoColorEstimateNonLinear(rawxyY,myxyY,myphosphors,lut,colorimeterhandler,displayhandler,options);

% plotting
PlotCIE1931xy([],phosphors,-1,0,1);
for mm=1:1:size(myxyY,2)
  set(handles.information_text,'String','Plotting measured data on the CIE1931 diagram...');
  axes(handles.color_figure); %#ok
  hold on;
  PlotCIE1931xy(rawxyY(1:2,mm),phosphors,0,1,1,1);
  PlotCIE1931xy(nonlinear_estimate{mm}.final_xyY(1:2),phosphors,0,1,1,0);
  set(handles.information_text,'String','Plotting measured data on the CIE1931 diagram...Done.');
end

% set the reusults to the GUI window
str_xyY=[]; str_rgb=[];
for mm=1:1:size(myxyY,2)
  str_xyY=[str_xyY,num2str(nonlinear_estimate{mm}.final_xyY(1)),',',num2str(nonlinear_estimate{mm}.final_xyY(2)),',',num2str(nonlinear_estimate{mm}.final_xyY(3)),';']; %#ok
  if get(handles.use_LUT_radiobutton,'Value')
    str_rgb=[str_rgb,num2str(nonlinear_estimate{mm}.final_LUT(1)),',',num2str(nonlinear_estimate{mm}.final_LUT(2)),',',num2str(nonlinear_estimate{mm}.final_LUT(3)),';']; %#ok
  else
    str_rgb=[str_rgb,num2str(nonlinear_estimate{mm}.final_RGB(1)),',',num2str(nonlinear_estimate{mm}.final_RGB(2)),',',num2str(nonlinear_estimate{mm}.final_RGB(3)),';']; %#ok
  end
end
set(handles.results_xyY_edit,'String',str_xyY);
set(handles.results_RGB_edit,'String',str_rgb);

% save the results
eval(sprintf('save %s nonlinear_estimate -append;',save_fname));

set(handles.information_text,'String','Automatic non-linear estimation of xyY values started...Done.');

return
