function data = read_varian(file)
% READ_VARIAN: read a Varian NMR directory
%
%   the argument can be any file from the NMR data set directory
%   which should contain a 'fid' and a 'procpar' file.
%
% Credits: DOSYToolbox, Copyright 2007-2008  <Mathias Nilsson>
% <http://dosytoolbox.chemistry.manchester.ac.uk>

  if ~isdir(file)
    file = fileparts(file);
  end
  
  % check that we have a 'fid' and 'procpar' file
  if exist(fullfile(file, 'fid')) && exist(fullfile(file, 'procpar'))
    data = varianimport(file);
  else
    data = []; % not a Varian NMR file
  end

function [variandata]=varianimport(inpath)

%   [variandata]=varianimport()
%   Imports PFG-NMR data in Varian format
%   Useage: Point to the fid directory that contains the raw data. The
%           imported data will be returned in the structure variandata
%           containing the following members:
%               procpar: structure containing the information in the Varian
%                        procpar file
%               ngrad: number of gradient levels
%               sw: spectral width (in ppm)
%               sp: start of spectrum (in ppm)
%               filename: original file name and path
%               np: number of complex data points per gradient level
%               sfrq: spectrometer frequency (im MHz)
%               at: acquisition time (in seconds)%
%               gamma: magnetogyric ratio of the nucleus
%               Gzlvl: gradient strengths
%               DELTA: diffusion time
%               delta: diffusion encoding time
%               dosyconstant: gamma.^2*delta^2*DELTAprime
%               FID: Free induction decays

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
if nargin==1
    path=inpath;
else
    path=uigetdir(pwd,'Choose the NMR experiment');
end

%path
if path
    
    
    %get the binary data first
    fidpath=fullfile(path, 'fid');

    fileid_fid=fopen(fidpath,'r','b');
    variandata.filename=path;
    
    %open file%
    %fileid_fid=fopen('fid','r','b')
    %read in file header
    nblocks=fread(fileid_fid,1,'int32');
    ntraces=fread(fileid_fid,1,'int32'); %#ok<NASGU>
    np=fread(fileid_fid,1,'int32');
    ebytes=fread(fileid_fid,1,'int32'); %#ok<NASGU>
    tbytes=fread(fileid_fid,1,'int32'); %#ok<NASGU>
    bbytes=fread(fileid_fid,1,'int32'); %#ok<NASGU>
    vers_id=fread(fileid_fid,1,'int16'); %#ok<NASGU>
    status=fread(fileid_fid,1,'int16'); %#ok<NASGU>
    nbheaders=fread(fileid_fid,1,'int32'); %#ok<NASGU>
    %disp('Importing fid data')
    
    complex_fid=zeros(np/2,nblocks);
    hp=waitbar(1,'Importing data');
    for m=1:nblocks
        waitbar(m/nblocks,hp,'Importing data');
        %read in block header
        scale=fread(fileid_fid,1,'int16'); %#ok<NASGU>
        status_block=fread(fileid_fid,1,'int16');
        bitstatus=bitget(uint16(status_block),1:16);
        index=fread(fileid_fid,1,'int16'); %#ok<NASGU>
        mode=fread(fileid_fid,1,'int16'); %#ok<NASGU>
        ctcount=fread(fileid_fid,1,'int32'); %#ok<NASGU>
        lpval=fread(fileid_fid,1,'float32'); %#ok<NASGU>
        rpval=fread(fileid_fid,1,'float32'); %#ok<NASGU>
        lvl=fread(fileid_fid,1,'float32'); %#ok<NASGU>
        tlt=fread(fileid_fid,1,'float32'); %#ok<NASGU>
        
        if bitstatus(4)==1
            fid_data=fread(fileid_fid,np,'float32');
        elseif bitstatus(3)==1
            fid_data=fread(fileid_fid,np,'int32');
        elseif bitstatus(3)==0
            fid_data=fread(fileid_fid,np,'int16');
        else
            error('Illegal combination in file header status')
        end
        
        
        complex_fid(:,m)=fid_data(1:2:np,:) + 1i*fid_data(2:2:np);
        
    end
    close(hp)
    fclose(fileid_fid);
    
    % Getting the parameters I need from the procpar
    %disp('Importing parameters')
    fidpath=fullfile(path, 'procpar');
    
    fileid_procpar=fopen(fidpath,'rt');
    k=1;
    while k
        parmline=fgetl(fileid_procpar);
        if parmline==-1;  break;  end;
        valueline=fgetl(fileid_procpar);
        if valueline==-1;  break;  end;
        parmcell=textscan(parmline,'%s %f %f %f %f %f %f %f %f %f %f');
        % valuecell=textscan(valueline,'%q',512);
        valuecell=textscan(valueline,'%s',1024);
        val_type=parmcell{2};
        val=str2double(cell2mat(valuecell{1}(1)));
        
        
        if val_type==2
            if isempty(char(valuecell{1}(2)))
                procpar.(char(parmcell{1}))='';
            end
            if val(1)>1
                m=1;
                cellarray=(valuecell{1}(2));
                while (val(1)>m)
                    extraline=fgetl(fileid_procpar);
                    cellarray{m+1}=textscan(extraline,'%s');
                    m=m+1;
                end
                procpar.(char(parmcell{1}))=cellarray;
                thirdline=fgetl(fileid_procpar);
                if thirdline==-1;  break;  end;
            else
                %sometimes the string can extend several lines - I think this
                %I have never seen this on a string array
                qtest=textscan(valueline,'%s',64);
                qtest=char(qtest{1}(2));
                
                if strcmp(qtest(end),'"')==0
                    strtmp=char(valuecell{1}(2));
                    thirdline=fgetl(fileid_procpar);
                    testcell=textscan(thirdline,'%q',64);
                    while str2double(cell2mat(testcell{1}(1)))~=0
                        strtmp=strcat(strtmp,thirdline);
                        thirdline=fgetl(fileid_procpar);
                        testcell=textscan(thirdline,'%q',64);
                    end
                    procpar.(char(parmcell{1}))=strtmp;
                else
                    procpar.(char(parmcell{1}))=char(valuecell{1}(2));
                    thirdline=fgetl(fileid_procpar);
                    if thirdline==-1;  break;  end;
                end
                
            end
        elseif  val_type==4
            if isempty(char(valuecell{1}(2)))
                procpar.(char(parmcell{1}))='';
            else
                procpar.(char(parmcell{1}))=char(valuecell{1}(2));
            end
            thirdline=fgetl(fileid_procpar);
            if thirdline==-1;  break;  end;
        else
            if val(1)==1
                procpar.(char(parmcell{1}))=str2double(valuecell{1}(2));
            else
                arrayval=zeros(val(1),1);
                for k=1:val(1)
                    arrayval(k)=str2double(valuecell{1}(k+1));
                end
                procpar.(char(parmcell{1}))=arrayval;
            end
            thirdline=fgetl(fileid_procpar);
            if thirdline==-1;  break;  end;
        end
        %     thirdline=fgetl(fileid_procpar);
        %     if thirdline==-1;  break;  end;
    end
    
    fclose(fileid_procpar);
    
    variandata.FID=complex_fid;
    variandata.np=np/2;
    variandata.procpar=procpar;
    if isfield(procpar,'gzlvl1') && length(procpar.gzlvl1)>1 %probably DOSY experiment
        if isfield(procpar,'DAC_to_G')
            variandata.Gzlvl=procpar.gzlvl1*procpar.DAC_to_G*0.01;
            variandata.DAC_to_G=procpar.DAC_to_G;
        else
            disp('Warning, no DAC_to_G parameter (possibly a conmverted data set), assuming values in Gauss cm^-1')
            variandata.Gzlvl=procpar.gzlvl1*0.01;
            variandata.DAC_to_G=1;
        end
        variandata.Gzlvl=variandata.Gzlvl';
        variandata.dosyconstant=procpar.dosygamma.^2*procpar.dosytimecubed;
        variandata.ngrad=length(procpar.gzlvl1);
        variandata.gamma=procpar.dosygamma;
        if isfield(procpar,'del')
            variandata.DELTA=procpar.del;
        else
            disp('Warning, no del parameter (possibly a converted data set), setting to default of 100 ms')
            variandata.DELTA=0.1;
        end
        if isfield(procpar,'gt1')
            variandata.delta=procpar.gt1;
        else
            disp('Warning, no gt1 parameter (possibly a converted data set), setting to default of 1 ms')
            variandata.delta=0.001;
        end
    else %probably a H experiment
        variandata.Gzlvl=0;
        variandata.dosyconstant=0;
        variandata.ngrad=1;
        variandata.gamma=267524618.573;
        variandata.DELTA='non existing';
        variandata.delta='non existing';
        variandata.DAC_to_G='non existing';
    end
    variandata.sw=procpar.sw/procpar.sfrq;
    variandata.at=procpar.at;
    variandata.sp=(procpar.rfp-procpar.rfl)/procpar.sfrq;
    
    if isfield(procpar,'sp1')
        variandata.sp1=(procpar.rfp1-procpar.rfl1)/procpar.sfrq;
    else
       variandata.sp1=[];
    end
    
    variandata.sfrq=procpar.sfrq;
    
    if isfield(procpar,'ni')
        variandata.ni=procpar.ni;
    else
        variandata.ni=1;
    end
    
    if isfield(procpar,'sw1')
        variandata.sw1=procpar.sw1/procpar.sfrq;        
    else
        variandata.sw1=[];
    end
    
    if isfield(procpar,'nchunk')
        variandata.nchunk=procpar.nchunk;
    end
    
    %Trying to cater for other arrays as well
    variandata.arraydim=procpar.arraydim;
    
    %MN 17Nov09 Now checking whether DELTA is numeric
    if isnumeric(variandata.DELTA) && length(variandata.DELTA)>1       % DRONE dataset
        disp('Assuming a DRONE type of data set ([1] M. Nilsson, A. Botana, G.A. Morris, Analytical Chemistry 81 (2009) 8119-8125.)')
        %restructuring for array definition
        nt2=1;
        for k=1:length(variandata.DELTA)
            if  k~=length(variandata.DELTA)
                if variandata.DELTA(k+1)~=variandata.DELTA(k)
                    nt2=nt2+1;
                end
            end
        end
        variandata.ngrad=variandata.ngrad/nt2;
        del=zeros(1,nt2);
        for k1=1:nt2
            del(k1)=variandata.DELTA((k1-1)*variandata.ngrad+1);
        end
        variandata.DELTA=del;
        variandata.ni=length(variandata.DELTA);
        %             variandata.exptype='DRONE'; %possible use in the future
    end
    
else
    variandata=[];
end


