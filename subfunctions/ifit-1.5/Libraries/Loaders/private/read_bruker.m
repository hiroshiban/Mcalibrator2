function data = read_bruker(file)
% READ_JEOL: read a Bruker NMR data set
%   the argument can be any file from the NMR data set directory
%   which should contain 
%      a 'acqus', 'pdata/1' directory, 'fid' or 'ser'
%
% Credits: 
% DOSYToolbox, Copyright 2007-2008  <Mathias Nilsson>
% <http://dosytoolbox.chemistry.manchester.ac.uk>
%
% matNMR, Jacco van Beek, 2009
% <http://matnmr.sourceforge.net/>

  if ~isdir(file)
    file = fileparts(file);
  end
  
  % check if we are accessing directly a 'pdata' directory
  [p,f] = fileparts(file);
  if strcmp(f, 'pdata')
    file = p;
  elseif ~isempty(strfind(p, 'pdata'))
    file = fullfile(p, '..');
  end
  
  % search for a 'acqus', 'pdata/1' directory, 'fid' or 'ser'
  if exist(fullfile(file,'acqus')) ...
    && (exist(fullfile(file,'fid')) || exist(fullfile(file,'ser'))) ...
    && exist(fullfile(file,'pdata','1'))
    data = brukerimport(file);
  else
    data = []; % not a Bruker NMR file
  end
  
  if ~isempty(data)
    % now check for processed data
    size1last = data.procs.SI;
    BlockingTD2=data.procs.XDIM;
    
    if isstruct(data.proc2s)
      size2last   = data.proc2s.SI;
      BlockingTD1 = data.proc2s.XDIM;
    else
      size2last   = 1;
      BlockingTD1 = 1;
    end
    
    %
    %If no blocking is specified then the full size will be taken
    %
    if (BlockingTD2 == 0), QTEMP3 = size1last;
    else                   QTEMP3 = BlockingTD2;
    end

    if (BlockingTD1 == 0), QTEMP4 = size2last;
    else                   QTEMP4 = BlockingTD1;
    end
    BrukerByteOrdering = ~data.procs.BYTORDP + 1;
    
    % read real part from processed   
    data.Real = readBrukerProcessedData(fullfile(file, 'pdata', '1', '1r'), ...
       size1last, size2last, QTEMP3, QTEMP4, ...
       BrukerByteOrdering);
    % read imaginary part from processed
  %     
    data.Imag = readBrukerProcessedData(fullfile(file, 'pdata', '1', '1i'), ...
       size1last, size2last, QTEMP3, QTEMP4, ...
       BrukerByteOrdering);
  end
     
  
% ------------------------------------------------------------------------------

function [brukerdata]=brukerimport(inpath)
%   [brukerdata]=brukerimport()
%   Imports PFG-NMR data in Bruker format
%   Useage: Point to the fid/ser file that contains the raw data. The
%           imported data will be returned in the structure brukerdata
%           containing the following members:
%               acqus: structure containing the information in the Bruker
%                      acqus file
%               ngrad: number of gradient levels
%               acqu2s: structure containing the information in the Bruker
%                       acqus2 file
%               sw: spectral width (in ppm)
%               procs: structure containing the information in the Bruker
%                      procs file
%               sp: start of spectrum (in ppm)
%               filename: original file name and path
%               np: number of complex data points per gradient level
%               sfrq: spectrometer frequency (im MHz)
%               at: acquisition time (in seconds)
%               gamma: magnetogyric ratio of the nucleus
%               Gzlvl: gradient strengths
%               DELTA: diffusion time
%               delta: diffusion encoding time
%               dosyconstant: gamma.^2*delts^2*DELTAprime
%               FID: Free induction decays
%               digshift: number of data points the fids have been
%                         left-shifted to deal with Brukers' digital
%                         filtering
%   Example:
%   See also: DOSYToolbox, dosy_mn, score_mn, decra_mn, mcr_mn, varianimport,
%             brukerimport, jeolimport, peakpick_mn, dosyplot_mn,
%             dosyresidual, dosyplot_gui, scoreplot_mn, decraplot_mn,
%             mcrplot_mn
%
%   This is a part of the DOSYToolbox
%   Copyright 2007-2008  <Mathias Nilsson>
%   This program is free software; you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation; either version 2 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License along
%   with this program; if not, write to the Free Software Foundation, Inc.,
%   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
%
%   Dr. Mathias Nilsson
%   School of Chemistry, University of Manchester,
%   Oxford Road, Manchester M13 9PL, UK
%   Telephone: +44 (0) 161 306 4465
%   Fax: +44 (0)161 275 4598
%   mathias.nilsson@manchester.ac.uk
%get the 1D proc pars first

if nargin==1
    path=inpath;
else
    [file path]=uigetfile('*','Choose the Bruker data file containing the FID (*.ser or *.fid)');
end
%% Main
if path
    %% set some default parameters
    brukerdata.sp1=[];
    brukerdata.ni=[];
    %% Read in acquisition parameters
    %% ---------- Read in direct dimension
    DataDim=0;
    acquspath=fullfile(path, 'acqus');
    
    DataDim=1;
    %%read in the lot
    kk=1;
    parmflag=0;
    procpar = str2struct(acquspath);
    
    brukerdata.acqus=procpar;

    a=procpar.PULPROG;
    a(1)=[];
    a(end)=[];
    brukerdata.pulprog=a;
    % procpar;
    %% ---------- Read in first indirect (diffusion) dimension
    %And then the 2D proc par
    %assuming that diffusion is always the second dimensionm
    
    acquspath=fullfile(path, 'acqu2s');
    if ~exist(acquspath)
      disp(['cannot open file: ' acquspath])
      disp('Probably a 1D experiment')
      DataDim=1;
      procpar2 = [];
    else        
      DataDim=2;
      %%read in the lot
      kk=1;
      parmflag=0;
      procpar2 = str2struct(acquspath);
    end
    
    brukerdata.acqu2s=procpar2;
    
    %% ---------- Read in second indirect (non diffusion) dimension
    
    %
    acquspath=fullfile(path, 'acqu3s');
    
    if ~exist(acquspath)
      %not a 3D experiment
      disp('Not a 3D experiment')
      procpar3 = [];
%         disp(['cannot open file: ' acquspath])
%         disp('Probably a 1D experiment - setting ngrad=1')
%         brukerdata.ngrad=1;
    else      
      DataDim=3;
      % brukerdata.ngrad=0;
      %%read in the lot
      kk=1;
      parmflag=0;
      procpar3 = str2struct(acquspath);
    end
    
    brukerdata.acqu3s=procpar3;
    
% procs
    
    
    %% Read Processing parameters
    %get processing parameters, if there are any
    brukerdata.sw=brukerdata.acqus.SW;
    procspath=fullfile(path, 'pdata','1','procs');
    
    if ~exist(procspath,'file')
        disp(['cannot open file: ' procspath])
        disp('estimating processing parameters from acquisition parameters');
        
        brukerdata.sf=brukerdata.acqus.BF1;
        brukerdata.sfo1=brukerdata.acqus.SFO1;
        brukerdata.sp=(brukerdata.sfo1/brukerdata.sf-1)*1e6+0.5*brukerdata.sw*(brukerdata.sfo1/brukerdata.sf)-brukerdata.sw;
        brukerdata.lp=0;
        brukerdata.rp=0;
        brukerdata.procs=brukerdata.acqus;
    else
        
        %%read in the lot
        kk=1;
        parmflag=0;
        procpar3 = str2struct(procspath);
        
        brukerdata.procs=procpar3;     
        brukerdata.sp=brukerdata.procs.OFFSET-brukerdata.sw;        
        brukerdata.lp=brukerdata.procs.PHC1;
        brukerdata.rp=-brukerdata.procs.PHC0 - brukerdata.lp;
        
        
    end
    
    procspath=fullfile(path, 'pdata','1','procs2');
    if exist(procspath,'file')
      brukerdata.proc2s = str2struct(procspath);
    else
      brukerdata.proc2s = brukerdata.acqu2s;
    end
    
    
    %% Sort out parameters in DOSY Toolbox format
    
    if DataDim==1
        disp('1D data')
        brukerdata.arraydim=1;
        brukerdata.ngrad=1;
        fidpath=fullfile(path, 'fid');
    elseif DataDim==2
        disp('2D data')
        brukerdata.arraydim=brukerdata.acqu2s.TD; %#ok<*ST2NM>    
        fidpath=fullfile(path, 'ser');
    elseif DataDim==3
        disp('3D data')
        brukerdata.arraydim=brukerdata.acqu2s.TD.*brukerdata.acqu3s.TD;        
        fidpath=fullfile(path, 'ser');
    else
       error(['Cannot determine data dimension'])
    end
    
    %set the sw in second dimension
    
   
    
    if DataDim==1
       
    elseif DataDim==2
        brukerdata.sw1=brukerdata.acqu2s.SW;
    elseif DataDim==3
       brukerdata.sw1=brukerdata.acqu3s.SW;
    else
       error(['Cannot determine data dimension'])
    end
          
    
    
    %Get the parameters I need for now (in units I like)
    brukerdata.filename=path(1:end-1);
    brukerdata.np=brukerdata.acqus.TD/2;
    brukerdata.sfrq=brukerdata.acqus.SFO1;
    brukerdata.at=brukerdata.np/(brukerdata.sw*brukerdata.sfrq);
    
    
    switch brukerdata.acqus.NUC1
        case '<1H>'
            brukerdata.gamma=267524618.573;
        case '<2H>'
            brukerdata.gamma=41066000;
        case '<10B>'
            brukerdata.gamma=28747000;
        case '<11B>'
            brukerdata.gamma=85847000;
        case '<13C>'
            brukerdata.gamma=67283000;
        case '<14N>'
            brukerdata.gamma=19338000;
        case '<15N>'
            brukerdata.gamma=-27126000;
        case '<17O>'
            brukerdata.gamma=-36281000;
        case '<19F>'
            brukerdata.gamma=251815000;
        case '<23Na>'
            brukerdata.gamma=70808000;
        case '<27Al>'
            brukerdata.gamma=69764000;
        case '<29Si>'
            brukerdata.gamma=-53190000;
        case '<31P>'
            brukerdata.gamma=108394000;          
            
        otherwise
            disp('unknown nucleus - defaulting to proton')
            brukerdata.gamma=267524618.573;
    end
    
    %setting  diffusion parameters
    gzlvlpath=fullfile(path, 'difflist');
    fileid_gzlvl=fopen(gzlvlpath,'rt');
    if (fileid_gzlvl~=-1)
        for k=1:brukerdata.acqu2s.TD
            parmline=fgetl(fileid_gzlvl);
            brukerdata.Gzlvl(k)=str2double(parmline);
            if parmline==-1;
                disp('Warning! -number of gradient values in difflist does not correspong to the number of gradient levels')
                break;
            end;
        end
        brukerdata.ngrad=length(brukerdata.Gzlvl);
        fclose(fileid_gzlvl);
    else
        disp('no difflist file; cannot read in gradient values')
        disp('If this is not a DOSY data file, it is completely normal')
    end
    
    if isfield(brukerdata,'Gzlvl')
        %DOSY data
        brukerdata.Gzlvl=brukerdata.Gzlvl*0.01; %conversion to T/m
        brukerdata.ngrad=length(brukerdata.Gzlvl);
        disp(['pulse programme is: ' brukerdata.pulprog])
        %check for pulseprogram
        if strncmpi('Doneshot',brukerdata.pulprog,8)
            disp('Doneshot sequence')
            brukerdata.dosyconstant=procpar.CNST(19).*brukerdata.gamma.^2;
            brukerdata.tau=procpar.CNST(18);
            brukerdata.DELTA=brukerdata.acqus.D(21);
            brukerdata.delta=2*brukerdata.acqus.P(31)*1e-6;
        elseif strncmpi('stebp',brukerdata.pulprog,5) || strncmpi('ledbp',brukerdata.pulprog,5)
            %bipolar sequence
            disp('bipolar sequence')
            brukerdata.DELTA=brukerdata.acqus.D(21)-brukerdata.acqus.D(17)/2;
            brukerdata.delta=2*brukerdata.acqus.P(31)*1e-6;
            brukerdata.tau=brukerdata.acqus.D(17)+brukerdata.acqus.P(31)*1e-6;
            
            brukerdata.dosyconstant=brukerdata.gamma.^2*brukerdata.delta.^2*(brukerdata.DELTA-brukerdata.delta/3-brukerdata.tau/2);
            %
            %     elseif strncmpi('dstebp',brukerdata.pulprog,6)
            %         disp('double stimulated echo bipolar sequence')
            
        elseif strncmpi('ste',brukerdata.pulprog,3) || strncmpi('led',brukerdata.pulprog,3)
            disp('monopolar sequence')
            brukerdata.DELTA=brukerdata.acqus.D(21);
            brukerdata.delta=brukerdata.acqus.P(31)*1e-6;
            brukerdata.dosyconstant=brukerdata.gamma.^2.*brukerdata.delta.^2.*(brukerdata.DELTA-brukerdata.delta/3);
            
            
            %     elseif strncmpi('dste',brukerdata.pulprog,4)
            %         disp('double stimulated echo monopolar sequence')
        else
            disp('unknown sequence; setting parameters to bipolar')
            
            brukerdata.DELTA=brukerdata.acqus.D(21);
            brukerdata.delta=2*brukerdata.acqus.P(31)*1e-6; %probably assuming bipolar pulse
            brukerdata.dosyconstant=brukerdata.gamma.^2*brukerdata.delta.^2*(brukerdata.DELTA-brukerdata.delta/3);
            
        end
    else
        disp('This does not appear to be a DOSY sequence; DOSY parameters set to non exisiting')
        brukerdata.Gzlvl='non existing';
        brukerdata.DELTA='non existing';
        brukerdata.delta='non existing';
        brukerdata.dosyconstant='non existing';
        brukerdata.ngrad=1;
        if DataDim==2
            brukerdata.ni=brukerdata.acqu2s.TD/2;
            brukerdata.sp1=brukerdata.sp;
        end
    end
    %% Read in the binary data
    %check the format of the data
    %The byte order will be big from SGI (MIPS processor) and little from
    %Linux/Windows (Intel), this is stored as the status parameters BYTORDA
    %(acquisition data) and BYTORDP (processed data).  Processed data is always
    %stored as scaled 32 bit integers, but acquisition data can in principle be
    %present as double precision (64 bit) data - this is indicated by the
    %status parameter DTYPA (0=integer, 2=double).  The double state is
    %automatically triggered if the raw data would overflow (but even in the
    %modern age of large effective ADC resolution this is probably a rare event!)
    
    switch brukerdata.acqus.BYTORDA
        case 0
            %little endian
            byte_format='l';
            
        case 1
            %big endian
            byte_format='b';
        otherwise
            error('unknown data format (BYTORDA)')
    end
    
    switch brukerdata.acqus.DTYPA
        case 0
            %32 bit integer
            byte_size='int32';
            
        case 1
            %double
            byte_size='double';
        otherwise
            error('unknown data format (BYTORDA)')
    end
    
    %Check that np is a multiple of 256 - otherwise correct
    % In a ser file each 1D fid will start at a 1024 byte block boundary even
    % if its size is not a multiple of 1k (256 points)
    corrpoints=rem(brukerdata.np*2,256);
    if corrpoints>0
        corrpoints=256-corrpoints;
        brukerdata.np=brukerdata.np+corrpoints/2;
    end
    
    %brukerdata.corrpoints=0
    fileid_FID=fopen(fidpath,'r',byte_format);
    FID=zeros(brukerdata.np,brukerdata.arraydim);
    impfid=fread(fileid_FID,brukerdata.np*2*brukerdata.arraydim,byte_size);
    compfid=complex(impfid(1:2:end),-impfid(2:2:end));
    
    for k=1:brukerdata.arraydim
        FID(:,k)=compfid((k-1)*brukerdata.np+1:k*brukerdata.np);
    end
    
    brukerdata.np=brukerdata.np-corrpoints/2;
    brukerdata.FID=FID((1:brukerdata.np),:);
    fclose(fileid_FID);
    %% Sort out the digital filtering
    % This is needed for converion of digitally filtered data - se longer
    % explanation at the end of the file
    BrukDigital=[
        2       44.750       46.000       46.311;
        3       33.500       36.500       36.530;
        4       66.625       48.000       47.870;
        6       59.083       50.167       50.229;
        8       68.563       53.250       53.289;
        12       60.375       69.500       69.551;
        16       69.531       72.250       71.600;
        24       61.021       70.167       70.184;
        32       70.016       72.750       72.138;
        48       61.344       70.500       70.528;
        64       70.258       73.000       72.348;
        96       61.505       70.667       70.700;
        128       70.379       72.500       72.524;
        192       61.586       71.333            0;
        256       70.439       72.250            0;
        384       61.626       71.667            0;
        512       70.470       72.125            0;
        768       61.647       71.833            0;
        1024       70.485       72.063            0;
        1536       61.657       71.917            0;
        2048       70.492       72.031            0];
    
            
    % first check if GRPDLY exists and use that if so
    decim=1;
    dspfvs=1;
    if isfield(brukerdata.acqus,'GRPDLY') && brukerdata.acqus.GRPDLY~=-1;
        brukerdata.digshift=brukerdata.acqus.GRPDLY;
        %disp('Hi')
    else
        %brukerdata.acqus.DECIM=0;
        
        if isfield(brukerdata.acqus,'DECIM')
            decim=brukerdata.acqus.DECIM;
            switch decim
                case 2
                    decimrow=1;
                case 3
                    decimrow=2;
                case 4
                    decimrow=3;
                case 6
                    decimrow=4;
                case 8
                    decimrow=5;
                case 12
                    decimrow=6;
                case 16
                    decimrow=7;
                case 24
                    decimrow=8;
                case 32
                    decimrow=9;
                case 48
                    decimrow=10;
                case 64
                    decimrow=11;
                case 96
                    decimrow=12;
                case 128
                    decimrow=13;
                case 192
                    decimrow=14;
                case 256
                    decimrow=15;
                case 384
                    decimrow=16;
                case 512
                    decimrow=17;
                case 768
                    decimrow=18;
                case 1024
                    decimrow=19;
                case 1536
                    decimrow=20;
                case 2048
                    decimrow=21;
                otherwise
                    disp('unknown value of DECIM parameter in acqus - cannot set compensation for digital filtering')
                    decim=0;
                    decimrow=Inf;
            end
        else
            disp('no DECIM parameter in acqus - cannot set compensation for digital filtering')
            decim=0;
            decimrow=Inf;
        end
        if isfield(brukerdata.acqus,'DSPFVS')
            dspfvs=brukerdata.acqus.DSPFVS;
            switch dspfvs
                case 10
                    dspfvsrow=2;
                case 11
                    dspfvsrow=3;
                case 12
                    dspfvsrow=4;
                otherwise
                    disp('unknown value of DSPVFS parameter in acqus - cannot set compensation for digital filtering')
                    dspfvs=0;
                    dspfvsrow=0;
            end
        else
            disp('no DSPFVS parameter in acqus - cannot set compensation for digital filtering')
            dspfvs=0;
        end
        if (decimrow>14) && (dspfvsrow==4)
            disp('unknown combination of DSPVFS and DECIM parameters in acqus - cannot set compensation for digital filtering')
            dspfvs=0;
            decim=0;
        end
        
    end
    if (decim==0) || (dspfvs==0)
        %No digital filtering
        disp('Parameters for digital filtering unknown - assumed to be data without digital filtering')
        brukerdata.digshift=0;
    elseif (decim==1) && (dspfvs==1)
        %digital filtering set by GRPDLY
        %do nothing
    else
        brukerdata.digshift=BrukDigital(decimrow,dspfvsrow);
    end
    %brukerdata.digshift=0
    brukerdata.digshift=round(brukerdata.digshift);
    % if brukerdata.digshift>0
    %     %left shift the fid
    %     for k=1:brukerdata.ngrad
    %        brukerdata.FID(:,k)= circshift(brukerdata.FID(:,k),-brukerdata.digshift);
    %     end
    % end
    
    brukerdata.np=length(brukerdata.FID(:,1));        
    %% Check the acquisition order for 3D Data
    if DataDim==3
        
        if isfield(procpar,'AQSEQ')
            if procpar.AQSEQ==0
                %all is fine - this is the structure we expect
                
            elseif procpar.AQSEQ==1
                % reversed order - lets fix it
                
                orgfid=brukerdata.FID;
                
               % brukerdata.FID=brukerdata.FID.*0;
                
                array2=brukerdata.arraydim/brukerdata.ngrad;
                
                for k=1:array2                
                    for p=1:brukerdata.ngrad   ;                    
                   % brukerdata.FID(:,k+array2*(p-1))=orgfid(:,(k-1)*brukerdata.ngrad +p);
                   brukerdata.FID(:,(k-1)*brukerdata.ngrad +p)=orgfid(:,k+array2*(p-1));
                    end
                end
                
                
            else
                %we're not sure
                disp('Unknown aquisition order')
            end
        else
            disp('no AQSEQ parameter. Cannot determine aquisition mode. Sticking with default')
        end
        
    else
        %not a 3D set
    end
else
    brukerdata=[];
end








%% INFORMATION ABOUT BRUKER DIGITAL FILTER
% For older versions of the Bruker hardware:
%
% A nice piece was found on the internet on how to calculate the number of points
% semi-automatically. Note that currently matNMR doesn't allow for the necessary
% negative-time apodization.
%
%
%    W. M. Westler and F.  Abildgaard
%    July 16, 1996
%
%    The introduction of digital signal processing by Bruker in their DMX
%    consoles also introduced an unusual feature associated with the data. The
%    stored FID no longer starts at its maximum followed by a decay, but is
%    prepended with an increasing signal that starts from zero at the
%    first data point and rises to a maximum after several tens of data points.
%    On transferring this data to a non-Bruker processing program such as FELIX,
%    which is used at NMRFAM, the Fourier transform leads to an unusable spectrum
%    filled with wiggles. Processing the same data with Bruker's Uxnmr
%    program yields a correct spectrum. Bruker has been rather reluctant
%    to describe what tricks are implemented during their processing protocol.
%
%    They suggest the data should be first transformed in Uxnmr and then inverse
%    transformed, along with a GENFID command, before shipping the data to another
%    program. Bruker now supplies a piece of software to convert the digitally
%    filtered data to the equivalent analog form.
%    We find it unfortunate that the vendor has decided to complicate
%    the simple task of Fourier transformation. We find that the procedure
%    suggested by Bruker is cumbersome, and more so, we are irritated since
%    we are forced to use data that has been treated with an unknown procedure.
%    Since we do not know any details of Bruker's digital filtration procedure
%    or the "magic" conversion routine that is used in Uxnmr, we have been forced
%    into observation and speculation. We have found a very simple, empirical
%    procedure that leads to spectra processed in FELIX that are identical,
%    within the noise limits, to spectra processed with Uxnmr. We deposit
%    this information here in the hope that it can be of some
%    use to the general community.
%    The application of a nonrecursive (or recursive) digital filter to time
%    domain data is accomplished by performing a weighted running average of
%    nearby data points. A problem is encountered at the beginning of
%    the data where, due to causality, there are no prior values. The
%    weighted average of the first few points, therefore, must include data
%    from "negative" time. One naive procedure, probably appropriate to NMR
%    data, is to supply values for negative time points is to pad the data with
%    zeros. Adding zeros (or any other data values) to the beginning of
%    the FID, however, shifts the beginning of the time domain data (FID) to
%    a later positive time. It is well known that a shift in the time
%    domain data is equivalent to the application of a frequency-dependent,
%    linear phase shift in the frequency domain. The 1st order phase shift
%    corresponding to a time shift of a single complex dwell point is 360 degrees
%    across the spectral width. The typical number of prepended points
%    found in DMX digitally filtered data is about 60 data points (see below),
%
%    the corresponding 1st order phase correction is ~21,000 degrees.
%    This large linear phase correction can be applied to the transformed data
%    to obtain a normal spectrum. Another, equivalent approach is to time
%    shift the data back to its original position. This results in the need
%    of only a small linear phase shift on the transformed data.
%    There is a question as what to do with the data preceding the actual
%    FID. The prepended data can be simply eliminated with the addition
%    of an equal number of zeros at the end of the FID (left shift). This
%    procedure, however, introduces "frowns" (some have a preference to refer
%    to these as "smiles") at the edge of the spectrum. If the sweep
%    width is fairly wide this does not generally cause a problem. The
%    (proper) alternative is to retain this data by applying a circular left
%    shift of the data, moving the first 60 or so points (see recommendations
%    below) to the end of the FID. This is identical to a Fourier transformation
%    followed by the large linear phase correction mentioned above. The
%    resulting FID is periodic with the last of the data rising to meet the
%    first data point (in the next period). Fourier transform of this
%    data results in an approximately phased spectrum. Further linear
%    phase corrections of up to 180 degrees are necessary. A zero fill applied
%    after a circular shift of the data will cause a discontinuity and thus
%    introduce sinc wiggles on the peaks. The usual correction for DC
%    offset and apodization of the data, if not done correctly, also results
%    in the frowns at the edges of the spectrum.
%
%    In our previous document on Bruker digital filters, we presented deduced
%    rules for calculating the appropriate number of points to be circular left
%    shifted. However, since then, newer versions of hardware (DQD) and software
%    has introduced a new set of values. Depending on the firmware versions
%    (DSPFVS) and the decimation rate (DECIM), the following lookup table will
%    give the circular shift values needed to correct the DMX data. The values
%    of DECIM and DSPFVS can be found in the acqus file in the directory containing
%    the data.
%
%     DECIM           DSPFVS 10       DSPFVS 11      DSPFVS 12
%
%       2              44.7500         46.0000        46.311
%       3              33.5000         36.5000        36.530
%       4              66.6250         48.0000        47.870
%       6              59.0833         50.1667        50.229
%       8              68.5625         53.2500        53.289
%      12              60.3750         69.5000        69.551
%      16              69.5313         72.2500        71.600
%      24              61.0208         70.1667        70.184
%      32              70.0156         72.7500        72.138
%      48              61.3438         70.5000        70.528
%      64              70.2578         73.0000        72.348
%      96              61.5052         70.6667        70.700
%     128              70.3789         72.5000        72.524
%     192              61.5859         71.3333
%     256              70.4395         72.2500
%     384              61.6263         71.6667
%     512              70.4697         72.1250
%     768              61.6465         71.8333
%    1024              70.4849         72.0625
%    1536              61.6566         71.9167
%    2048              70.4924         72.0313
%
%
%    The number of points obtained from the table are usually not integers.  The appropriate procedure is to circular shift (see protocol for details) by the integer obtained from truncation of the obtained value and then the residual 1st order phase shift that needs to be applied can be obtained by multiplying the decimal portion of the calculated number of points by 360.
%
%    For example,
%
%    If DECIM = 32, and DSPFVS = 10,
%    then #points 70.0156
%
%    The circular shift performed on the data should be 70 complex points and the linear
%    phase correction after Fourier transformation is approximately 0.0156*360= 5.62 degrees.
%
%    Protocol:
%
%       1. Circular shift (rotate) the appropriate number of points in the data indicated by
%       the  DECIM parameter. (see above formulae).
%
%       2. After the circular shift, resize the data to the original size minus
%       the number of shifted points. This will leave only the part of the
%       data that looks like an FID. Baseline correction (BC) and/or apodization
%       (EM etc.) should be applied only on this data, otherwise "In come the frowns."
%
%       Since the first part of the data (the points that are shifted) represents
%       negative time, a correct apodization would also multiply the shifted points
%       by a negative time apodization. The data size is now returned to
%       its original size to reincorporate the shifted points. There may
%       still be a discontinuity between the FID portion and the shifted points
%       if thelast point of the FID portion is not at zero. This will cause
%       sinc wiggles in the peaks.
%
%       3. Applying a zero fill to this data will lead to a discontinuity in the data
%       between the rising portion of the shifted points and the zero padding.
%       To circumvent this problem, the shifted points are returned (by circular
%       shift) to the front of the data, the data is zero filled, and then the
%       first points are shifted again to the end of the zero filled data.
%
%       4) The data can now be Fourier transformed and the residual calculated
%       1st order phase correction can be applied.
%
%
%
% For newer versions of the Bruker hardware:
%
%     For firmware versions of 20 <= DSPFVS <= 23 the GRPDLY parameter directly shows the number of
%     points that need to be shifted.
%
%     Thanks for Bruker for supplying this information!
%
%
%
%26-09-'00


%
%
%
% matNMR v. 3.9.0 - A processing toolbox for NMR/EPR under MATLAB
%
% Copyright (c) 1997-2009  Jacco van Beek
% jabe@users.sourceforge.net
%
%
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
%
% --> gpl.txt
%
% Should yo be too lazy to do this, please remember:
%    - The code may be altered under the condition that all changes are clearly marked 
%      with your name and the date and that none of the names currently present in the 
%      code are removed.
%
% Furthermore:
%    -Please update the BugFixes.txt (i.e. the changelog file)!
%    -Please inform me of useful changes and annoying bugs!
%
% Jacco
%
%
% ====================================================================================
%
%
% readBrukerProcessedData.m reads XWINNMR processed spectra.
%
% syntax: readBrukerProcessedData(File Name, sizeTD2, sizeTD1, Blocking Factor TD2, Blocking Factor TD1, ByteOrdering);
%
% For the Blocking Factor look in the procs and proc2s files in the directory
% of the spectrum. Needed are the XDIM parameters (procs is for TD2 and proc2s
% is for TD1).
%
% ByteOrdering is an optional parameter which specifies the byte ordering, as this may vary across
% architectures. By default it is 1, meaning "big endian". The other possibilities are
%     2 = little endian
%
% Jacco van Beek
% ETH Zurich
% 20-07-'00

function Return = readBrukerProcessedData(FileName, SizeTD2, SizeTD1, BlockingTD2, BlockingTD1, ByteOrdering);

if (nargin == 5)
  ByteOrdering = 1;
end

if (ByteOrdering == 1)
  ByteOrdering = 'b';
else
  ByteOrdering = 'l';
end

Return = zeros(SizeTD1,SizeTD2);

f1 = SizeTD1 / BlockingTD1;
f2 = SizeTD2 / BlockingTD2;

id = fopen(FileName, 'r', ByteOrdering);

k=1:BlockingTD2;
for o=1:f1
  for p=1:f2
    for i=1:BlockingTD1;
      [a,count] = fread(id, BlockingTD2, 'int32');
      Return(i + (o-1)*BlockingTD1 ,k + (p-1)*BlockingTD2) = a.';
    end
  end
end

fclose(id);

Return = fliplr(flipud(Return));
