function config = iLoad_ini
% config = iLoad_ini User definitions of specific import formats to be used by iLoad
%
% Each format is specified as a structure with the following fields
%   method:   function name to use, called as method(filename, options...)
%   extension:a single or a cellstr of extensions associated with the method
%   patterns: list of strings to search in data file. If all found, then method
%             is qualified. The patterns can be regular expressions.
%   name:     name of the method/format
%   options:  additional options to pass to the method.
%             If given as a string they are catenated with file name
%             If given as a cell, they are given to the method as additional arguments
%   postprocess: function called from iData/load after file import, to assign aliases, ...
%             called as iData=postprocess(iData)
%
% formats should be sorted from the most specific to the most general.
% Formats will be tried one after the other, in the given order.
% System wide loaders are tested after user definitions.
%
% These formats can be obtained using [config, configfile]=iLoad('','load config').
% the iLoad_ini configuration file can be saved in the Preference directory
% using [config, configfile] = iLoad(config,'save config').
% A list of all supported formats is shown with iLoad('formats');
%
% See also: iLoad, save, iData/saveas

% definition of formats ========================================================

    ILL_normal.name       ='ILL Data (normal integers)';
    ILL_normal.patterns   ={'RRRR','AAAA','FFFF','IIII'};
    ILL_normal.options    ='--headers --fortran --catenate --fast --binary --makerows=IIII --makerows=FFFF --silent ';
    ILL_normal.method     ='read_anytext';
    
    ILL_integers.name       ='ILL Data (large integers)';
    ILL_integers.patterns   ={'RRRR','AAAA','FFFF','JJJJ'};
    ILL_integers.options    ='--headers --fortran --catenate --fast --binary --makerows=JJJJ --makerows=FFFF --silent ';
    ILL_integers.method     ='read_anytext';
    
    ILL_float.name          ='ILL Data (floats only)';
    ILL_float.patterns      ={'RRRR','AAAA','FFFF'};
    ILL_float.options       ='--headers --fortran --catenate --fast --binary --makerows=FFFF --silent ';
    ILL_float.method        ='read_anytext';
    
    ILL_general.name       ='ILL Data (general)';
    ILL_general.patterns   ={'RRRR','AAAA','SSSS'};
    ILL_general.options    ='--headers --fortran --catenate --fast --binary --makerows=FFFF --makerows=JJJJ --makerows=IIII --silent ';
    ILL_general.method     ='read_anytext';
    
    ILL_TAS_pol.name       ='ILL TAS Data (polarized)';
    ILL_TAS_pol.patterns   ={'PAL','POSQE:','PARAM:','DATA_:','LOCAL:','USER_:'};
    ILL_TAS_pol.options    =['--fast --binary --headers --silent ' ...
                        '--section=PARAM --section=VARIA --section=ZEROS --section=DATA ' ...
                        '--section=POLAN --section=STEPS ' ...
                        '--metadata=LOCAL --metadata=USER --metadata=EXPNO --metadata=DATE ' ...
                        '--metadata=INSTR --metadata=COMND --metadata=TITLE --metadata=MULTI '];
    ILL_TAS_pol.method     ='read_anytext';
    ILL_TAS_pol.postprocess='load_ill_tas'; % load_ill_tas
    ILL_TAS_pol.extension  ='scn';
    
    ILL_TAS.name       ='ILL TAS Data';
    ILL_TAS.patterns   ={'POSQE:','PARAM:','DATA_:','LOCAL:','USER_:'};
    ILL_TAS.options    =['--fast --binary --headers --silent ' ...
                        '--section=PARAM --section=VARIA --section=ZEROS --section=DATA ' ...
                        '--section=STEPS ' ...
                        '--metadata=LOCAL --metadata=USER --metadata=EXPNO --metadata=DATE --metadata=DATA ' ...
                        '--metadata=INSTR --metadata=COMND --metadata=TITLE --metadata=MULTI '];
    ILL_TAS.method     ='read_anytext';
    ILL_TAS.postprocess='load_ill_tas'; % load_ill_tas
    ILL_TAS.extension  ='scn';
    
    spec.name       ='SPEC';
    spec.patterns   ={'#F','#D','#S'};
    spec.options    ='--fast --binary --headers --metadata=''#S '' --comment=NULL --silent ';
    spec.method     ='read_anytext';
    spec.extension  ={'spc','spec'};
    
    mcstas_scan.name       ='McStas Scan DAT output';
    mcstas_scan.patterns   ={'# type: multiarray_1d','# variables:','# title: Scan of'};
    mcstas_scan.options    =['--fast --binary --headers --comment=NULL --metadata=variables --silent ' ...
                         '--metadata=xlabel --metadata=ylabel --metadata=xvars --metadata=component --metadata=Param --metadata=Creator ' ];
    mcstas_scan.method     ='read_anytext';
    mcstas_scan.postprocess='load_mcstas_scan';
    
    mcstas_list.name       ='McStas list monitor';
    mcstas_list.patterns   ={'Format: McStas with text headers','# type: array_2d','# xlabel: List of neutron events'};
    mcstas_list.options    = ['--fast --binary --headers --comment=NULL --metadata=variables --silent --catenate ' ...
		    '--metadata=xlabel --metadata=Creator ' ...
		    '--metadata=ylabel --metadata=xylimits --metadata=component --metadata=Param ' ];
    mcstas_list.method     ='read_anytext';
    mcstas_list.postprocess='load_mcstas_1d';
    
    mcstas_2D.name       ='McStas 2D monitor';
    mcstas_2D.patterns   ={'Format: McStas with text headers','# type: array_2d'};
    mcstas_2D.options    = ['--fast --binary --headers --comment=NULL --metadata=variables --silent ' ...
		    '--metadata=Errors --metadata=Events --metadata=xlabel --metadata=Creator ' ...
		    '--metadata=ylabel --metadata=zlabel --metadata=xylimits --metadata=component --metadata=Param ' ];
    mcstas_2D.method     ='read_anytext';
    mcstas_2D.postprocess='load_mcstas_1d';
    
    mcstas_1D.name       ='McStas 1D monitor';
    mcstas_1D.patterns   ={'Format: McStas with text headers','# type: array_1d'};
    mcstas_1D.options    =['--fast --binary --headers --comment=NULL --silent --metadata=variables  ' ...
        '--metadata=xlabel --metadata=ylabel  --metadata=component --metadata=Param --metadata=Creator ' ];
    mcstas_1D.method     ='read_anytext';
    mcstas_1D.postprocess={'load_xyen','load_mcstas_1d'};
    
    mcstas_sim.name       ='McStas sim file';
    mcstas_sim.extension  ='sim';
    mcstas_sim.patterns   ={'begin simulation','Format: McStas'};
    mcstas_sim.options    ='--fast --binary --headers  --comment=NULL --silent ';
    mcstas_sim.method     ='read_anytext';
    mcstas_sim.postprocess='opensim';
    
    mcstas_sqw.name       ='McStas Sqw table';
    mcstas_sqw.patterns   ={'Sqw data file for Isotropic_Sqw'};
    mcstas_sqw.options    ='--fast --binary  --headers --comment=NULL --silent ';
    mcstas_sqw.method     ='read_anytext';
    mcstas_sqw.postprocess='opensqw';
    mcstas_sqw.extension  ='sqw';
    
    mcstas_powder.name       ='McStas powder table (LAZ/LAU)';
    mcstas_powder.patterns   ={'lattice_a','column_'};
    mcstas_powder.options    ='--fast --binary  --headers --comment=NULL --silent ';
    mcstas_powder.method     ='read_anytext';
    mcstas_powder.postprocess='openlaz';
    mcstas_powder.extension  ={'laz','lau'};
    
    chalkriver.name     ='ChalkRiver CNBC';
    chalkriver.patterns ={'Run ','Seq ','Rec ','Mode ','Temp:','File '};
    chalkriver.options  ='--fast --binary  --headers --comment=NULL --silent --section=Run --metadata=File --metadata=Sig';
    chalkriver.method   ='read_anytext';
    chalkriver.postprocess='load_chalkriver';
    
    ISIS_spe.name       ='ISIS/SPE tof data';
    ISIS_spe.options    ='--headers --fortran  --catenate --fast --binary --comment=NULL --silent ';
    ISIS_spe.method     ='read_anytext';
    ISIS_spe.patterns   ={'Phi Grid'};
    ISIS_spe.extension  ='spe';
    
    ILL_inx.name       ='ILL INX tof data';
    ILL_inx.options    ='';
    ILL_inx.method     ='read_inx';
    ILL_inx.postprocess='openinx';
    ILL_inx.extension  ='inx';
    
    STL_ascii.name     ='STL/SLP 3D ascii';
    STL_ascii.method   ='read_stl';
    STL_ascii.options  ='ascii';
    STL_ascii.patterns ={'facet','vertex','endfacet'};
    STL_ascii.extension={'stl','stla','slp'};
    STL_ascii.postprocess='openstl';
    
    STL_binary.name     ='STL 3D binary';
    STL_binary.method   ='read_stl';
    STL_binary.options  ='binary';
    STL_binary.extension={'stl','stlb'};
    STL_binary.postprocess='openstl';
    
    OBJ.name            ='OBJ Wavefront 3D';
    OBJ.method          ='read_obj';
    OBJ.extension       ='obj';
    OBJ.patterns        ={'v ', 'f '};
    
    CFL.name     ='CFL FullProf crystallography file';
    CFL.patterns ={'Spgr','Atom'};
    CFL.method   ='read_anytext';
    CFL.options  ='--headers --fortran --catenate --fast --binary --section=Atom --silent --metadata=Spgr --metadata=Cell --metadata=Spgr ';
    CFL.extension={'cfl'};
    CFL.postprocess='opencfl';
    
    CIF.name     = 'CFL/PCR FullProf, CIF, INS/RES/SHX ShellX file (CrysFML)';
    CIF.method   ='read_cif';
    CIF.extension={'cif','pcr','pcr','cfl','ins','res','shx'};
    CIF.postprocess='opencif';
    
    PDB.name            ='Protein Data Bank';
    PDB.extension       ='pdb';
    PDB.method          ='read_pdb';
    PDB.patterns        ={'HEADER','COMPND','SOURCE','EXPDTA','AUTHOR','REVDAT'};
    PDB.postprocess     = 'load_xyen';
    
    OFF_ascii.name      ='OFF 3D ascii';
    OFF_ascii.method    ='read_anytext';
    OFF_ascii.options   ='--fast --binary --headers --comment=NULL --metadata=OFF --silent';
    OFF_ascii.extension ='off';
    OFF_ascii.patterns  ={'\<OFF\>'};
    OFF_ascii.postprocess='openoff';
    
    PLY_ascii.name      ='PLY 3D ascii';
    PLY_ascii.method    ='read_anytext';
    PLY_ascii.options   ='--fast --binary --headers --comment=NULL --silent';
    PLY_ascii.extension ='ply';
    PLY_ascii.patterns  ={'ply','format ascii','element','end_header'};
    PLY_ascii.postprocess='openply';
    
    EZD.name            ='EZD electronic density map';
    EZD.method          ='read_anytext';
    EZD.options         ='--fortran --headers --binary --fast --catenate --comment=NULL --silent';
    EZD.extension       ='ezd';
    EZD.patterns        ={'EZD_MAP','CELL','EXTENT'};
    EZD.postprocess     ='this.Data.MAP = reshape(this.Data.MAP, this.Data.EXTENT);';
    
    yaml.name           = 'YAML';
    yaml.method         = 'read_yaml';
    yaml.extension      = {'yaml','yml'};
    
    json.name           = 'JSON';
    json.method         = 'read_json';
    json.extension      = 'json';
    
% binary formats ===============================================================

    nmr_jeol.name       = 'JEOL NMR data set';
    nmr_jeol.method     = 'read_jeol';
    nmr_jeol.extension  = {'hdr','bin','asc','jdf'};
    
    nmr_varian.name     = 'Varian NMR data set';
    nmr_varian.method   = 'read_varian';

    nmr_bruker.name     = 'Bruker NMR data set';
    nmr_bruker.method   = 'read_bruker';
    
    ESRF_edf.name       ='EDF ESRF Data Format';
    ESRF_edf.options    ='';
    ESRF_edf.method     ='read_edf';
    ESRF_edf.extension  ='edf';
    
    Roper_SPE.name      ='SPE CCD by WinView from Roper Scientific / PI Acton';
    Roper_SPE.method    ='read_spe';
    Roper_SPE.extension ='spe';
    
    Mar_CCD.name        ='MarResearch CCD Camera';
    Mar_CCD.method      ='read_mar';
    Mar_CCD.extension   ={'mar','mccd'};
    
    Andor_SIF.name      ='Andor SIF CCD Camera';
    Andor_SIF.method    ='read_sif';
    Andor_SIF.extension ='sif';
    Andor_SIF.patterns  = 'Andor Technology Multi-Channel File';
    
    ADSC_CCD.name       ='ADSC CCD Camera';
    ADSC_CCD.method     ='read_adsc';
    ADSC_CCD.extension  ='img';
    ADSC_CCD.patterns   ={'HEADER_BYTES','CCD_IMAGE_SATURATION'};
    
    Matlab_FIG.name     ='Matlab Figure';
    Matlab_FIG.method   ='read_fig';
    Matlab_FIG.extension='fig';
    Matlab_FIG.postprocess='load_fig';
    
    Analyze.name        ='Analyze volume data';
    Analyze.method      ='read_analyze';
    Analyze.postprocess ='openhdr';
    Analyze.extension   ={'hdr','img'};
    
    CBF.name            ='Crystallographic Binary File';
    CBF.extension       ='cbf';
    CBF.method          ='read_cbf';
    CBF.postprocess     ='opencbf';
    CBF.patterns        ={'###CBF: VERSION'};
    
    MRC.name            ='MRC/CCP4 electron density map';
    MRC.extension       ={'mrc','ccp4','map','res'};
    MRC.method          ='read_mrc';
    
    NifTI.name          = 'NifTI-1 MRI volume data';
    NifTI.extension     = 'nii';
    NifTI.method        = 'read_nii';
    
    Igor.name           = 'Igor WaveMetrics Wave data';
    Igor.extension      = 'ibw';
    Igor.method         = 'read_igor';
    
% definition of configuration
    config.loaders =  { ILL_normal, ILL_integers, ILL_float, ILL_general, ILL_TAS_pol, ILL_TAS, ...
	       spec, mcstas_scan, mcstas_list, mcstas_2D, mcstas_1D, mcstas_sim, mcstas_sqw, mcstas_powder, ...
	       chalkriver, ISIS_spe, ILL_inx, STL_ascii, PDB, OFF_ascii, PLY_ascii, CFL, EZD, ...
	       nmr_jeol, nmr_bruker, nmr_varian, ...
	       yaml, json, ...
	       ESRF_edf, Mar_CCD, Roper_SPE, Andor_SIF, ADSC_CCD, Matlab_FIG, ...
	       Analyze, CBF, STL_binary, MRC, NifTI, Igor, CIF };
	       
	  config.UseSystemDialogs = 'yes'; % no: use uigetfiles, else defaults to 'uigetfile'
	  config.FileName         = [ mfilename ' (default configuration from ' which(mfilename) ')' ];
	  config.MeX.looktxt      = 'yes'; % no: use binary version, yes: use MeX
	  config.MeX.cif2hkl      = 'no';
	  
    
