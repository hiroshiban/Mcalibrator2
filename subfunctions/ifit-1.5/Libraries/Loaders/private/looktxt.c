/*****************************************************************************
*
*                     Program looktxt.c
*
* looktxt version Looktxt 1.3 $Revision: 1166 $ (14 June 2013) by Farhi E. [farhi@ill.fr]
*
* Usage: looktxt [options] file1 file2 ...
* Action: Search and export numerics in a text/ascii file.
*   This program analyses files looking for numeric parts.
*   Each identified numeric field is named and exported
*   into an output filename, usually as a structure with fields
*     ROOT.SECTION.FIELD = VALUE
*   In order to sort your data, you may specify as many --section
*   and --metadata options as necessary
* All character sets are supported as long as numbers have format
*   [+-][0-9].[0-9](e[+-][0-9])
* Infinite and Not-a-Number values are also supported.
*
* Example: looktxt -f Matlab -s PARAM -s DATA filename
* Usual options are: --fast --binary --force --comment=NULL
*
* MeX usage: looktxt(arg1, ...)
*   all arguments are separated, and given as strings, such as in
*   looktxt('--format=MATfile','filename','-H')
*
* Main Options are:
* --binary   or -b    Stores numerical matrices into an additional binary
*                     double file, which makes further import much faster.
* --catenate or -c    Catenates similar numerical fields
* --catenate=0|1      Do-not (slower) or do catenate similar fields 
* --force    or -F    Overwrites existing files
* --format=FORMAT     Sets the output format for generated files. See below
*       -f FORMAT
* --fortran --wrapped Catenates wrapped/single Fortran-style output lines with
*                     previous matrices (default)
* --fortran=0         Do not use Fortran compatibility mode 
* --headers  or -H    Extracts headers for each numerical field
* --help     or -h    Show this help
* --section=SEC       Classifies fields into section matching word SEC
*       -s SEC
* --metadata=META     Extracts lines containing word META as user meta data
*         -m META
*
* Other Options are:
* --append            Append to existing files. This also sets --force
* --fast              Uses a faster reading method, requiring numerics
*                     to be separated by \n\t\r\f\v and spaces only
* --makerows=NAME     All fields matching NAME are transformed into row vectors
* --metadata-only     Only extracts selected meta data (smaller files)
* --names_lower       Converts all names into lower characters
* --names_upper       Converts all names into upper characters
* --names_length=LEN  Sets the maximum length to use for names (32)
* --names_root=ROOT   Sets the base name for structures to ROOT
*                     Default is to use the output file name
*                     Use --names_root=NULL or 0 not to use root level.
* --nelements_min=MIN Only extracts numericals with at least MIN elements
* --nelements_max=MAX Only extracts numericals with at most MAX elements
* --outfile=FILE      Sets output file name. Extension, if missing, is added
*        -o FILE      depending on the FORMAT. FILE may be stdout or stderr
* --struct=CHAR       Will use CHAR as struct builder. Default is '.'
*                     Use --struct=NULL or 0 not to use structures.
*                     Alternatively you may use '_'.
* --verbose  or -v    Displays analysis information
* --silent            Silent mode. Only displays errors/warnings
* --comment=COM       Sets comment characters (ignore line if at start)
* --eol=EOL           Sets end-of-line characters
* --separator=SEP     Sets word seperators (handled as spaces)
*
* Available output formats are (default is Matlab):
*   "Matlab" "Scilab" "IDL" "XML" "HTML" "Octave" "Raw"
*   Adding 'binary' to the FORMAT name will do the same as --binary.
*   The LOOKTXT_FORMAT environment variable may set the default FORMAT to use.
*
* content: C language
* compile with : cc -O2 looktxt.c -o looktxt
*
* History:
* 0.86  (04/11/97) not effective
* 0.87  (26/03/99) works quite fine. Some bugs.
* 0.88  (09/04/99) improvements and 'table' output
* 0.89  (02/07/99) corrected grouping error for isolated numerics
* 0.89a (27/03/00) multi plateform handling
* 0.90  (03/07/00) debug mode ok, no more lktmp00 file
* 0.91  (26/07/00) new options -S (struct) -H (num header)
* 0.93  (21/08/01) -T, filename in file
* 1.00  (23/08/04) New VERSION with more output formats
* 1.03  (21/11/07) Fixed redundant numbered Sections (e.g. SPEC files)
* 1.05  (12/12/08) Solved memleaks with valgrind
* 1.06  (29/05/09) GCC-4 support (libc/vfprintf is not suited for us)
* 1.0.7 (09/07/09) fixed metadata export, speed-up by factor 2.
* 1.0.8 (24/09/09) upgrade MeX support. Build with 'make mex'
* 1.2.0 (02/04/12) added direct export to MAT files
* 1.3.3 (14/06/13) fixed HDF5 output for large files. Improve non fscan data_get. Added NeXus/XML
*
*****************************************************************************/

/*
    Looktxt: Search and export numerics in a text/ascii file
    Copyright (C) 2009  E. Farhi <farhi at ill.eu>, Institut Laue Langevin

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

/* Identification ********************************************************* */

/* USE_MEX  is defined when compiled as a MeX from Matlab (triggers USE_MAT)
   compile with:
     mex -O looktxt.c -DUSE_MEX
 * Under Windows 32 bits
     mex ('-O','-v','looktxt.c',['-L"' matlabroot '\sys\lcc\lib"'],'-lcrtdll')
   in this case, MAT files are not written, but data is directly send back as MEX output arguments 
 */

/* USE_MAT is defined when support for export to MAT is requested 
   to compile as a standalone executable with MAT file support use:
     export MATLABROOT=/usr/local/matlab
     export ARCH=glnxa64
     gcc -I$MATLABROOT/extern/include -L$MATLABROOT/bin/$ARCH -DUSE_MAT -O2 -o looktxt -lmat -lmx looktxt.c
   WARNING: the Matlab HDF libraries are incompatible with NeXus: 
            do not mix MAT/MEX + NeXus (causes SEG FAULT)
 */
 
/* USE_NEXUS is defined when support for export to NeXus/HDF5 is requested 
   to compile use:
     gcc -DUSE_NEXUS -O2 -o looktxt looktxt.c -lNeXus
 */


#define AUTHOR  "Farhi E. [farhi@ill.fr]"
#define DATE    "14 June 2013"
#ifndef VERSION
#define VERSION "1.3 $Revision: 1166 $"
#endif

#ifdef __dest_os
#if (__dest_os == __mac_os)
#define MAC
#endif
#endif

#ifndef EXIT_FAILURE
#define EXIT_FAILURE -1
#endif

#ifndef EXIT_SUCCESS
#define EXIT_SUCCESS 0
#endif

#ifndef SEEK_SET
#define SEEK_SET 0
#endif

#if defined(WIN32) || defined(_WIN32) || defined(_WIN64)
#define LK_PATHSEP_C '\\'
#define LK_PATHSEP_S "\\"
#else  /* !WIN32 */
#ifdef MAC
#define LK_PATHSEP_C ':'
#define LK_PATHSEP_S ":"
#else  /* !MAC */
#define LK_PATHSEP_C '/'
#define LK_PATHSEP_S "/"
#endif /* !MAC */
#endif /* !WIN32 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <time.h>
#include <stdarg.h>
#include <math.h>

#if !defined(WIN32) && !defined(_WIN32) && !defined(_WIN64)
#include <unistd.h>

#else /* WIN32 */
#include <direct.h>
#include <io.h>
#endif /* WIN32 */

#ifdef __LCC__
/* redefine is* functions, which are broken in LCC */
char lk_toupper(char c) { if (c>='a' && c<='z') return(c+'A'-'a'); else return(c); }
char lk_tolower(char c) { if (c>='A' && c<='Z') return(c-'A'+'a'); else return(c); }
int  lk_isalpha(char c) { return( (c>='a' && c<='z') || (c>='A' && c<='Z') ); }
int  lk_isdigit(char c) { return( c>='0'&& c<='9' ); }
int  lk_isalnum(char c) { return( lk_isdigit(c) || lk_isalpha(c) ); }
int  lk_isprint(char c) { return( c>=' ' && c <='~' ); }
#else
#define lk_toupper toupper
#define lk_tolower tolower
#define lk_isalpha isalpha
#define lk_isdigit isdigit
#define lk_isalnum isalnum
#define lk_isprint isprint

#endif

/* MATLAB support *********************************************************** */

/* as MEX, we use USE_MAT, but send the blocks directly to matlab engine */

#ifdef  USE_MEX
#ifndef USE_MAT
#define USE_MAT
#endif
#include <mex.h>	   /* include MEX library for Matlab */
#define printf       mexPrintf	/* Addapt looktxt.c code to Mex syntax */
#define print_stderr mexPrintf
#define exit(ret)    { char msg[1024]; sprintf(msg, "Looktxt/mex exited with code %i\n", ret); if (ret) mexErrMsgTxt(msg); }
#define main         MexMain
#endif

#ifdef USE_MAT
#include <mat.h>     /* MAT file support */
#include <matrix.h>  /* mxArray support */
#ifdef USE_NEXUS
#undef USE_NEXUS     /* NeXus and Matlab use incompatible libraries */
#endif 
#define malloc  mxMalloc
#define realloc mxRealloc
#define calloc  mxCalloc
#define free    NoOp      /* do not free in MeX mode */
#endif 

/* USE_NEXUS/HDF support ******************************************************* */
#ifdef USE_NEXUS
#include <napi.h>
#endif

/* Declarations ************************************************************* */

#define Ceol       "\n\f"
#define Ccomment   "#%"
#define Cseparator "\t\v\r,; $()[]{}=|<>&\"/\\:'"

#define Bnumber      1  /* flags */
#define Balpha       2
#define Bpoint       4
#define Beol         8
#define Bexp        16
#define Bsign       32
#define Bcomment    64
#define Bseparator 128
#define ALLOC_BLOCK 10000 /* size of blocks to pre-allocate in Lists */

#define MAX_LENGTH 1024   /* length of buffer */
#define MAX_TXT4BIN 100   /* size beyond which binary storage is prefered (-b option) */
/*
#ifdef WIN32
#define size_t long
#define time_t long
#endif
*/

/* Functions declaration ************************************************** */
/*
static int pfprintf(FILE *f, char *fmt, char *fmt_args, ...);
void *mem(size_t size);
char *memfree(void *p);
char *str_dup(char *string);
char *str_dup_n(char *string, int n);
char *str_cat(char *first, ...);
char *str_free(char *string);
char *str_rep(char *string, char *from, char *to);
char *str_valid(char *string, int n);
char *str_valid_struct(char *string, char struct_char);
char *str_reverse(char *string);
char *str_extractline(char *header, char *field, int *offset);
int   ischr(char c, char *category);
char *str_lastword(char *string);

struct fileparts_struct fileparts_init(void);
struct fileparts_struct fileparts(char *name);
void                    fileparts_free(struct fileparts_struct parts);

char *try_open_target(struct fileparts_struct parts, char force);
struct file_struct file_init(void);
struct file_struct file_open(char *name, struct option_struct options);
void               file_close(struct file_struct file);

struct format_struct format_init(struct format_struct formats[], char *request);

struct strlist_struct strlist_init(void);
void                  strlist_free(struct strlist_struct list);
struct strlist_struct strlist_add(struct strlist_struct *list, char *element);
struct strlist_struct strlist_add_void(struct strlist_struct *list, void *element);
int                   strlist_search(struct strlist_struct list, char *element);

struct option_struct options_init(void);
void                 options_free(struct option_struct options);
struct option_struct options_parse(struct option_struct options, int argc, char *argv[]);

struct data_struct data_init(void);
void               data_print(struct data_struct field)
void               data_free(struct data_struct field);
char              *data_get_char(struct file_struct file, long start, long end);
double            *data_get_double(struct file_struct file, struct data_struct field);

struct table_struct *table_init(void);
void                table_add(struct table_struct *table, struct data_struct data);
void                table_free(struct table_struct *table);

struct table_struct file_scan(struct file_struct file, struct option_struct options);
int file_write_headfoot(struct file_struct file, struct option_struct options, char *format);
int file_write_tag(struct file_struct file, struct option_struct options,
                       char *section, char *name, char *value, char *format);
int file_write_section(struct file_struct file, struct option_struct options,
                       char *section, char *format);
int file_write_field_data(struct file_struct file, struct data_struct field, char *format);
int file_write_field_array(struct file_struct file, struct data_struct field,
                          struct option_struct options, char *format);
int file_write_field_array_matnexus(struct file_struct file,
                          struct option_struct options,
                          struct data_struct field, struct strlist_struct to_catenate)
struct write_struct file_write_getsections(struct file_struct file,
                       struct option_struct options,
                       struct table_struct *ptable);
int file_write_target(struct file_struct file, struct table_struct table,
                      struct option_struct options);

void print_usage(char *pgmname, struct option_struct options);
int  parse_files(struct option_struct options, int argc, char *argv[]);
int  main(int argc, char *argv[]);
*/

#ifndef USE_MEX
int print_stderr(char *format, ...) {
  va_list ap;
  int ret=0;

  va_start(ap, format);
  ret=vfprintf(stderr, format, ap);

  va_end(ap);
  return(ret);
}
#endif
int NoOp(void *pointer)
{
  /* do not free in MeX mode */
  /* mxFree((void *)pointer); */
  return 0;
}

/* Structure definitions ************************************************** */

struct fileparts_struct {
  char *FullName;
  char *Path;
  char *Name;
  char *Extension;
};

struct file_struct {
  char  *Source    ;  /* original source file full name */
  char  *TargetTxt ;  /* target text file with path and extension */
  char  *TargetBin ;  /* optional target binary file */
  FILE  *SourceHandle;  /* original source file handle */
  FILE  *TxtHandle ;  /* target text handle */
  FILE  *BinHandle ;  /* optional target binary handle */
  char  *Path      ;  /* the Path to the source file name */
  char  *SourceName;  /* the source name without the path nor the extension */
  char  *TargetName;  /* the target root name (source_ext) */
  char  *Extension ;  /* the source file extension */
  char  *RootName  ;  /* ROOT Name to use for structure fields */
  size_t Size;        /* source File size in bytes */
  time_t Time;        /* source Creation date */
#ifdef USE_MAT
  mxArray *mxRoot;    /* hold the mxArray Matlab structure */
  mxArray *mxData;    /* Root.Data */
  mxArray *mxHeaders; /* Root.Headers */
#endif
#ifdef USE_NEXUS
  NXhandle nxHandle;
#endif
};

struct format_struct {
  char *Name;
  char *Extension;
  char *Header;
  char *Footer;
  char *BeginSection;
  char *EndSection;
  char *AssignTag;
  char *BeginData;
  char *EndData;
  char *BinReference;
};

struct strlist_struct {
  long   nalloc;  /* total allocated entries */
  long   length;  /* current table length (filled elements) */
  char   Name[32];
  char **List;    /* an array of (pointers to char) */
};

struct option_struct {
  long  sources_nb; /* total number of files to process */
  int   files_to_convert_Array[MAX_LENGTH];/* index of argv[] for files to be processes */
  long  file_index; /* index of processed file (in case of a pack of files) */
  char  use_struct; /* will build struct field names */
  char  use_binary; /* will use binary external file to hold matrices/vectors 1:double */
  char  catenate  ; /* will catenate similar fields (name+size)   */
  char  force     ; /* force (over write) output files */
  char  out_table ; /* will output table field */
  char  out_headers;/* will output char header for each numeric field */
  char  verbose   ; /* 0:silent, 1: normal, 2: verbose, 3: debug */
  char  fortran   ; /* catenate fortran vectors */
  char  names_lowup; /* field names are lower/upper case */
  int   names_length; /* length of field names */
  char *separator ; /* separators to use */
  char *comment   ; /* comments start char (to end of line) */
  char *eol       ; /* end of line char */
  char  metadata_only;
  char *openmode  ;
  char *option_list;
  char *names_root;
  char *pgname    ;
  char  fast      ; /* 0: general method, 1: fast method using fscanf (isspace as separator) */
  char  test      ; /* 1: test mode, does not write anything to disk */
  struct format_struct    format;   /* the output file format to use */
  struct fileparts_struct outfile;  /* user specified output file name */
  struct strlist_struct   sections; /* sections to search for */
  struct strlist_struct   metadata; /* metadata to search for */
  struct strlist_struct   makerows; /* field to transform into row */
  long  nelements_min;  /* extracts only fields with n_elements >= min */
  long  nelements_max;  /* extracts only fields with n_elements <= max */
  char  ismatnexus;     /* 0=TxT/Bin format ; 1=MAT; 2=HDF/NeXus compressed; 3=MEX */
};

/* lists stuctures ******************************************************** */

struct data_struct {
  char *Name;       /* name of the numeric field (extracted from Header) */
  char *Name_valid; /* valid name (with only alpha) */
  char *Header;     /* char header of the field */
  char *Section;    /* name of the section the field is in (extracted from Header) */
  long  index;      /* index of this data block */
  long  rows, columns;  /* field numeric dimensions */
  long  n_start, n_end; /* indexes of numeric part in original file */
  long  c_start, c_end; /* indexes of char part in original file */
};

struct table_struct {
  long   nalloc;              /* total allocated entries (field) */
  long   length;              /* current length in table (filled elements) */
  char  *Name;                /* Name of the table */
  struct data_struct *List;   /* an array of data_struct */
};

int options_warnings=100;

/* Format definitions ***************************************************** */

#define NUMFORMATS 13
#ifdef USE_MEX
#define LOOKTXT_FORMAT "MEX"    /* default format when in Matlab/MeX mode */
mxArray *mxOut=NULL;                 /* a cell array or single struct */
#else
#define LOOKTXT_FORMAT "Matlab" /* default format */
#endif
#define ROOT_SECTION   "looktxt_root"

/* format_struct {
   Name, Extension,
   Header, Footer, BeginSection, EndSection, AssignTag, BeginData, EndData, BinReference }
 */
struct format_struct Global_Formats[NUMFORMATS] = {
  { "Matlab", "m",
    "function %NAM=%NAM()\n"
      "%% %TXT %FMT file generated by " __FILE__ " " VERSION " from %SRC (size %SIZ)\n"
      "%% To import, use 'matlab> s=%NAM'\n",
    "%% End of file %TXT generated from %SRC\n"
      "%% in-line function to read binary blocks\n"
      "function d=bin_ref(f,b,m,n)\n"
      "  [fid,mess]=fopen(f,'rb');\n"
      "  if fid == -1, disp([ 'Error opening bin file ' f ': ' mess ]); end\n"
      "  fseek(fid,b,-1);\n"
      "  d=fread(fid,m*n,'double'); fclose(fid);\n"
      "  if m*n ~= numel(d), disp([ 'File ' f ': read ' num2str(numel(d)) ' elements but expected ' mat2str([ m n ]) ]); f=dir(f); disp(f); end\n"
      "  d=reshape(d,n,m);\n"
      "  d=d'; return\n",
    "%% Begin Section %BAS%SEC '%NAM'\n",
    "%% End   Section %BAS%SEC '%NAM'\n",
    "%BAS%SEC%NAM = '%VAL';\n",
    "%BAS%SEC%NAM = [\n",
    "]; %% %NAM\n",
    " bin_ref('%FIL',%BEG,%ROW,%COL); \n"
  },
#ifdef USE_MAT
  { "MATfile/HDF","mat", 
    "Header Matlab MAT", "Footer", "BeginSection", "EndSection", "AssignTag", "BeginData", "EndData" },
#else
  { NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL },
#endif
#ifdef USE_MEX
  { "MEX","", 
    "Header Matlab MAT", "Footer", "BeginSection", "EndSection", "AssignTag", "BeginData", "EndData" },
#else
  { NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL },
#endif
#ifdef USE_NEXUS
  { "NeXus5/HDF5","h5",
    "HDF5 Nexus", "Footer", "BeginSection", "EndSection", "AssignTag", "BeginData", "EndData" },
  { "NeXus4/HDF4","h4",
    "HDF4 Nexus", "Footer", "BeginSection", "EndSection", "AssignTag", "BeginData", "EndData" },
  { "NeXus/XML","xml",
    "XML NeXus", "Footer", "BeginSection", "EndSection", "AssignTag", "BeginData", "EndData" },
#else
  { NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL },
  { NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL },
  { NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL },
#endif
  { "Scilab", "sci",
    "function %NAM = %NAM()\n"
      "// %TXT %FMT function generated by " __FILE__ " " VERSION " from %SRC (size %SIZ)\n"
      "// To import, use scilab> exec('%NAM.sci',-1); s=%NAM\n"
      "mode(-1); //silent execution\n",
    "// End of file %TXT generated from %SRC\n"
      "// in-line function to read binary blocks\n"
      "function d=bin_ref(f,b,m,n)\n"
      "  f=mopen(f,'rb'); mseek(f,b);\n"
      "  d=mget(m*n,'d',f); mclose(f); d=matrix(d,[n m]);\n"
      "  d=d'; return\n",
    "// Begin Section %BAS%SEC '%NAM'\n",
    "// End   Section %BAS%SEC '%NAM'\n",
    "%BAS%SEC%NAM = '%VAL';\n",
    "%BAS%SEC%NAM = [\n",
    "];\n",
    " bin_ref('%FIL',%BEG,%ROW,%COL); \n"
  },
  { "IDL", "pro",
    "; %TXT %FMT function generated by " __FILE__ " " VERSION " from %SRC (size %SIZ)\n"
      "; To import, use idl> s=%NAM()\n\n"
      "function bin_ref,f,b,m,n\n"
      "; in-line function to read binary blocks\n"
      "  d=read_binary(f, data_type=8, data_dims=[m,n], data_start=b)\n"
      "  d=reform(d,[m,n])\n"
      "  return,transpose(d)\n"
      "end ; FUN bin_ref\n\n"
      "pro stv,S,T,V\n"
      "; procedure set-tag-value that does S.T=V\n"
      "sv=size(V)\n"
      "T=strupcase(T)\n"
      "TL=strupcase(tag_names(S))\n"
      "id=where(TL eq T)\n"
      "sz=[0,0,0]\n"
      "vd=n_elements(sv)-2\n"
      "type=sv[vd]\n"
      "if id(0) ge 0 then d=execute('sz=SIZE(S.'+T+')')\n"
      "if (sz(sz(0)+1) ne sv(sv(0)+1)) or (sz(0) ne sv(0)) $\n"
      "  or (sz(sz(0)+2) ne sv(sv(0)+2)) $\n"
      "  or type eq 8 then begin\n"
      " ES = ''\n"
      " for k=0,n_elements(TL)-1 do begin\n"
      "  case TL(k) of\n"
      "   T:\n"
      "   else: ES=ES+','+TL(k)+':S.'+TL(k)\n"
      "  endcase\n"
      " endfor\n"
      " d=execute('S={'+T+':V'+ES+'}')\n"
      "endif else d=execute('S.'+T+'=V')\n"
      "end ; PRO stv\n\n"
      "function %NAM\n" ROOT_SECTION " ={Target:'%TXT'}\n",
    "return,%BAS\nend ; FUN %BAS\n; End of file %TXT generated from %SRC\n",
    "; Begin Section %BAS %SEC '%NAM'\n",
    "; End   Section %BAS %SEC '%NAM'\n",
    "stv,%SEC,'%NAM','%VAL'\n",
    "%NAM= ","%NAM=transpose(reform(%NAM,%COL,%ROW,/over))\n"
    "stv,%SEC,'%NAM',%NAM & %NAM=0\n",
    " bin_ref('%FIL',%BEG,%ROW,%COL) "
  },
  { "XML", "xml",
    "<?xml version=\"1.0\" ?>\n<!--\n"
    "%TXT %FMT file generated by " __FILE__ " " VERSION " from %SRC (size %SIZ)\n-->\n",
    "<!-- End of file %TXT generated from %SRC ->\n",
    "<%SEC name=\"%NAM\">\n", "</%SEC>\n",
    "<%NAM>%VAL</%NAM>\n",
    "<%NAM> \n","</%NAM>\n"," float64(file='%FIL',offset=%BEG,m=%ROW,n=%COL) "
  },
  { "YAML", "yaml",
    "%%YAML 1.1\n"
    "# %TXT %FMT file generated by " __FILE__ " " VERSION " from %SRC (size %SIZ)\n-->\n",
    "# End of file %TXT generated from %SRC\n",
    "%NAM:\n", "\n",
    "%SEC%NAM: %VAL\n",
    "%SEC%NAM:\n","]\n",
    " float64(file='%FIL',offset=%BEG,m=%ROW,n=%COL) \n"
  },
  { "HTML", "html",
    "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD %DAT//EN\"\n"
      "\"http://www.w3.org/TR/html4/strict.dtd\">\n"
      "<HTML><HEAD><TITLE>%TXT from %SRC</TITLE></HEAD>\n"
      "<BODY><H1>%TXT %FMT file generated by " __FILE__ " " VERSION " from %SRC (size %SIZ)</H1><br>\n",
    "End of file %TXT generated from %SRC<br></BODY></HTML>\n",
    "<h3><a name=\"%SEC\">Section %BAS %SEC</a></h3><br>\n",
    "[end of <a href=\"#%SEC\">%BAS %SEC</a>]<br>\n",
    "<b>%BAS%SEC%NAM= </b>'%VAL'<br>\n","<b>%BAS%SEC%NAM = [ \n</b><pre>","]\n</pre><br>"," float64(file='%FIL',offset=%BEG,m=%ROW,n=%COL) "
  },
  { "Octave", "m",
    "function %NAM=%NAM()\n"
      "%% %TXT %FMT file generated by " __FILE__ " " VERSION " from %SRC (size %SIZ)\n"
      "%% To import, use 'octave> %NAM'\n",
    "endfunction\n%% End of file %TXT generated from %SRC\n"
      "%% in-line function to read binary blocks\n"
      "function d=bin_ref(f,b,m,n)\n"
      "  f=fopen(f,'rb'); fseek(f,b,-1);\n"
      "  d=fread(f,m*n,'double'); fclose(f); d=reshape(d,n,m);\n"
      "  d=d'; return\n"
      "endfunction\n",
    "%% Begin Section %BAS%SEC '%NAM'\n",
    "%% End   Section %BAS%SEC '%NAM'\n",
    "%BAS%SEC%NAM = '%VAL';\n",
    "%BAS%SEC%NAM = [\n",
    "];\n",
    " bin_ref('%FIL',%BEG,%ROW,%COL); \n"
  },
  { "Raw", "txt",
    "# %TXT %FMT file generated by " __FILE__ " " VERSION " from %SRC (size %SIZ)\n",
    "# End of file %TXT generated from %SRC\n",
    "# Begin Section %BAS%SEC '%NAM'\n",
    "# End   Section %BAS%SEC '%NAM'\n",
    "# %BAS%SEC%NAM = '%VAL'\n",
    "# %BAS%SEC%NAM\n","",
    " float64(file='%FIL',offset=%BEG,m=%ROW,n=%COL) \n"
  }
};

/* memory/string functions (from McStas/memory.c) ****************************
* contains functions for:
*   memory        (mem)
*   strings       (str_)
*   formats       (format_)
*   string lists  (strlist_)
*   files         (fileparts_)
*   data items    (data_)
*   data tables   (table_)
*****************************************************************************/

/*****************************************************************************
* mem: Allocate memory. This function never returns NULL; instead, the
*     program is aborted if insufficient memory is available.
*****************************************************************************/
void *mem(size_t size)
{
  void *p=NULL;
  if (!size) return(NULL);
  p = (void *)calloc(1, size);  /* Allocate and clear memory. */
  if(p == NULL) {
    print_stderr( "Error: Memory exhausted during allocation of size %ld [looktxt:mem:%d].", (long)size, __LINE__);
    exit(EXIT_FAILURE);
  }
  return p;
}

/*****************************************************************************
* memfree: Free memory allocated with mem().
*****************************************************************************/
char *memfree(void *p)
{
  if (p) free(p);
  return (NULL);
}

/*****************************************************************************
* str_dup: Allocate a new copy of a string.
*****************************************************************************/
char *str_dup(char *string)
{
  char *s=NULL;

  if (!string) return(NULL);
  s = mem(strlen(string)+1);
  strcpy(s, string);
  return s;
}

/*****************************************************************************
* str_dup_n: Allocate a new copy of initial N chars in a string.
*****************************************************************************/
char *str_dup_n(char *string, size_t n)
{
  char *s=NULL;

  if (!string) return(NULL);
  if (!n || n > strlen(string)) n = strlen(string);
  s = mem(n + 1);
  strncpy(s, string, n);
  s[n] = '\0';
  return s;
}

/*****************************************************************************
* str_cat: Allocate a new string to hold the concatenation of given strings.
*     Arguments are the strings to concatenate, terminated by NULL.
*****************************************************************************/
char *str_cat(char *first, ...)
{
  char *s=NULL;
  va_list ap;
  size_t size;
  char *arg=NULL;

  if (!first) return (NULL);
  size = 1;     /* Count final '\0'. */
  va_start(ap, first);
  for(arg = first; arg != NULL; arg = va_arg(ap, char *))
    size += strlen(arg);  /* Calculate string size. */
  va_end(ap);
  s = mem(size);
  size = 0;
  va_start(ap, first);
  for(arg = first; arg != NULL; arg = va_arg(ap, char *)) {
    strcpy(&(s[size]), arg);
    size += strlen(arg);
  }
  va_end(ap);
  return s;
}

/*****************************************************************************
* str_free: Free memory for a string. (alias to mem )
*****************************************************************************/
char *str_free(char *string)
{
  return(memfree(string));
}

/*****************************************************************************
* str_rep: Replaces a token by an other (of SAME length) in a string
*     This function modifies 'string'
*****************************************************************************/
char *str_rep(char *string, char *from, char *to)
{
  char *p=NULL;

  if (!string || !strlen(string) || !from || !to) return(string);
  if (strlen(from) != strlen(to)) return(string);

  p   = string;

  while (( p = strstr(p, from) ) != NULL) {
    long index;
    for (index=0; index<strlen(to); index++) p[index]=to[index];
  }
  return(string);
}

/*****************************************************************************
* str_quote: Allocate a new string holding the result of quoting the input string.
*     The result is suitable for inclusion in C source code.
*****************************************************************************/
char *str_quote(char *string)
{
  char *badchars = "\\\"\r\n\t\a\b\f\v";
  char *quotechars = "\\\"rntabfv";
  char *q=NULL, *res=NULL, *ptr=NULL;
  size_t len=0, pass=0;
  int c;
  char new[5];

  /* Loop over the string twice, first counting chars and afterwards copying
     them into an allocated buffer. */
  for(pass = 0; pass < 2; pass++)
  {
    char *p = string;

    if(pass == 0)
      len = 0;    /* Prepare to compute length */
    else
      q = res = mem(len + 1); /* Allocate buffer */
    /* Notice the cast to unsigned char; without it, the isprint(c) below will
       fail for characters with negative plain char values. */
    while((c = (unsigned char)(*p++)))
    {
      ptr = strchr(badchars, c);
      if(ptr != NULL)
        sprintf(new, "\\%c", quotechars[ptr - badchars]);
      else if(lk_isprint(c))
        sprintf(new, "%c", c);
      else
        sprintf(new, "\\%03o", c);
      if(pass == 0)
        len += strlen(new); /* Count in length */
      else
        for(ptr = new; (*q = *ptr) != 0; ptr++)
          q++;  /* Copy over chars */
    }
  }
  return res;
}

/*****************************************************************************
* str_valid: Allocate a copy of string made only with valid chars
*     copy 'string' into 'valid', replacing invalid characters by '_'
*****************************************************************************/
char *str_valid(char *string, size_t n)
{
  long i;
  char *valid=NULL;
  char *tmp1 =NULL;
  char *tmp2 =NULL;

  if (!string || !strlen(string)) return(NULL);
  if (!n || n > strlen(string)) n=strlen(string);
  tmp2 = tmp1 = str_dup_n(string, n);

/* find first alpha char */
  while (tmp2[0] && !lk_isalpha(tmp2[0])) tmp2++;

  if (!tmp2[0] || tmp2 >= tmp1+strlen(tmp1)) {
    str_free(tmp1);
    tmp2 = tmp1 = str_cat("lk_", string, NULL);
  }

/* convert non valid following chars in name into _ */
  for (i=0; i < strlen(tmp2); i++) {
    if (!lk_isalnum(tmp2[i]) && tmp2[i] != '_') tmp2[i] = '_';
  }
  valid = str_dup((tmp2 && tmp2[0]) ? tmp2 : "Name");
  tmp1=str_free(tmp1);
  return(valid);
} /* str_valid */

/*****************************************************************************
* str_valid_struct: Allocate a copy of string made only with valid chars
*     and appending a 'struct' char at the end
*     copy 'string' into 'valid', replacing invalid characters by '_'
*****************************************************************************/
char *str_valid_struct(char *string, char char_struct)
{
  char *ret=NULL;
  long i;
  char *valid=NULL;
  char *tmp1 =NULL;
  char *tmp2 =NULL;
  if (!string || !strlen(string)) return(str_dup(""));

  tmp2 = tmp1 = str_dup(string);

/* find first alpha char */
  while (tmp2[0] && !lk_isalpha(tmp2[0])) tmp2++;

/* convert non valid following chars in name into _ */
  for (i=0; i < strlen(tmp2); i++) {
    if (!lk_isalnum(tmp2[i]) && tmp2[i] != '_') tmp2[i] = '_';
    else if (char_struct && tmp2[i] == char_struct) tmp2[i] = '_';
  }

  valid = str_dup((tmp2 && tmp2[0]) ? tmp2 : "Name");
  tmp1=str_free(tmp1);
  if (char_struct) {
    char str_struct[]=".";
    str_struct[0] = char_struct;
    ret = str_cat(valid, str_struct, NULL);
    valid=str_free(valid);
  } else ret=valid;
  return(ret);

} /* str_valid_struct */

/*****************************************************************************
* str_valid_eol: Update 'string' without EOL nor quotes (does not allocate a copy)
*****************************************************************************/

char *str_valid_eol(char *header, struct option_struct options)
{
  if (!header || !strlen(header)) return(header);
  /* if output does not support \n in chars, make header valid */
  if (header && strlen(header) && options.out_headers)
  if (strstr(options.format.Name, "Matlab")
  ||  strstr(options.format.Name, "Scilab")
  ||  strstr(options.format.Name, "Octave")
  ||  strstr(options.format.Name, "MEX")
  ||  strstr(options.format.Name, "IDL")) {
    char *p=header;
    while ((p = strpbrk(p, "\n\r\f\t\v")) != NULL) *p = ';';
    p=header;
    while ((p = strpbrk(p, "'")) != NULL) *p = '"';
  }
  if (header[strlen(header)-1] == ';') header[strlen(header)-1]=' ';
  return(header);
} /* str_valid_eol */

/*****************************************************************************
* str_reverse: Allocate a copy of 'string' in reverse order
*****************************************************************************/
char *str_reverse(char *string)
{
  char *reverted=NULL;
  size_t index;
  size_t index_reverted;

  if (!string) return(NULL);
  reverted = str_dup(string);
  index_reverted = strlen(reverted)-1;
  for (index=0; index < strlen(string); index++) {
    reverted[index_reverted--] = string[index];
  }

  return(reverted);
} /* str_reverse */

/*****************************************************************************
* str_extractline:  look for field in header, starting at offset
*     return allocated end of line containing field
*     or NULL in case of failure (error, not found)
*     offset (if non NULL) is set to new position after call
*****************************************************************************/
char *str_extractline(char *header, char *field, size_t *offset)
{
  char *header_offset=NULL;
  char *value    =NULL;
  char *start_pos=NULL;
  char *end_pos  =NULL;

  if (!header || !field || !strlen(field) || !strlen(header)) return (NULL);

  if (offset && *offset > 0) header_offset = header+ (*offset);
  else header_offset = header;

  start_pos = strstr(header_offset, field);
  if (start_pos) { /* get end of line '\n \r \f EOF' */
    start_pos += strlen(field);
    end_pos = strchr(start_pos, '\n');
    if (!end_pos) end_pos = strchr(start_pos, '\r');
    if (!end_pos) end_pos = strchr(start_pos, '\f');
    if (!end_pos) end_pos = strchr(start_pos, EOF);
    if (!end_pos) end_pos = strchr(start_pos, '\0');
  } else return (NULL);

  if (!end_pos || end_pos <= start_pos) return(NULL);

  value = (char *)mem(end_pos - start_pos);
  strncpy(value, start_pos, end_pos - start_pos);
  if (offset && *offset >= 0) *offset = end_pos - header;
  return(value);
} /* str_extractline */

/*****************************************************************************
* ischr: Returns TRUE when character 'c' belongs to 'category'
*****************************************************************************/
int ischr(char c, char *category)
{
  return (strchr( category   ,c) != NULL);
}

/*****************************************************************************
* str_lowup: returns the string into lower/upper chars. type=0, 'u' or 'l'
*****************************************************************************/
char *str_lowup(char *name, char type)
{
  int i;
  if (!type) return(name);
  for (i=0; i<strlen(name); i++)
    if (type == 'l') name[i] = lk_tolower(name[i]);
    else             name[i] = lk_toupper(name[i]);
  return (name);
}

/*****************************************************************************
* str_lastword: Allocate a new string containing its last word
*     A word starts with a letter followed by letters/digits/underscores
*****************************************************************************/
char *str_lastword(char *string)
{
  char *reverted=NULL;
  char *p_end=NULL, *p_start=NULL;
  char *word=NULL;
  char *tmp0=NULL, *tmp1=NULL;

  if (!string || !strlen(string)) return(NULL);
  reverted = str_reverse(string);
  /* find the first alpha/digit/underscore character */
  p_end = strpbrk(reverted, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_");
  if (!p_end) { str_free(reverted); return(NULL); }
  p_start = p_end;
  for (p_start = p_end;
       (p_start < reverted+strlen(reverted)) && (lk_isalnum(*p_start) || *p_start=='_');
       p_start++);
  tmp0 = str_dup_n(p_end, p_start - p_end);
  tmp1 = str_reverse(tmp0);
  /* now check that name does not start with  "_" Cnumber */
  for (p_start=tmp1; (lk_isdigit(*p_start) || *p_start=='_') && p_start<tmp1+strlen(tmp1); p_start++);
  word = str_dup(p_start);
  reverted=str_free(reverted); tmp0=str_free(tmp0); tmp1=str_free(tmp1);
  return(word);
} /* str_lastword */

/*******************************************************************************
* pfprintf: just as fprintf with positional arguments %N$t, 
*   but with (char *)fmt_args being the list of arg type 't'.
*   Needed as the vfprintf is not correctly handled on some platforms.
*   1- look for the maximum %d$ field in fmt
*   2- look for all %d$ fields up to max in fmt and set their type (next alpha)
*   3- retrieve va_arg up to max, and save pointer to arg in local arg array
*   4- use strchr to split around '%' chars, until all pieces are written
*   returns number of arguments written.
* Warning: this function is restricted to only handles types t=s,g,i,li
*          without additional field formating, e.g. %N$t
*******************************************************************************/
static int pfprintf(FILE *f, char *fmt, char *fmt_args, ...)
{
  #define MyNL_ARGMAX 50
  char  *fmt_pos=NULL;

  char *arg_char[MyNL_ARGMAX];
  int   arg_int[MyNL_ARGMAX];
  long  arg_long[MyNL_ARGMAX];
  double arg_double[MyNL_ARGMAX];

  char *arg_posB[MyNL_ARGMAX];  /* position of '%' */
  char *arg_posE[MyNL_ARGMAX];  /* position of '$' */
  char *arg_posT[MyNL_ARGMAX];  /* position of type */

  int   arg_num[MyNL_ARGMAX];   /* number of argument (between % and $) */
  int   this_arg=0;
  int   arg_max=0;
  va_list ap;

  if (!f || !fmt_args || !fmt) return(-1);
  for (this_arg=0; this_arg<MyNL_ARGMAX;  arg_num[this_arg++] =0); this_arg = 0;
  fmt_pos = fmt;
  while(1)  /* analyse the format string 'fmt' */
  {
    char *tmp=NULL;

    arg_posB[this_arg] = (char *)strchr(fmt_pos, '%');
    tmp = arg_posB[this_arg];
    if (tmp)
    {
      arg_posE[this_arg] = (char *)strchr(tmp, '$');
      if (arg_posE[this_arg] && tmp[1] != '%')
      {
        char  this_arg_chr[10];
        char  printf_formats[]="dliouxXeEfgGcs\0";

        /* extract positional argument index %*$ in fmt */
        strncpy(this_arg_chr, arg_posB[this_arg]+1, arg_posE[this_arg]-arg_posB[this_arg]-1);
        this_arg_chr[arg_posE[this_arg]-arg_posB[this_arg]-1] = '\0';
        arg_num[this_arg] = atoi(this_arg_chr);
        if (arg_num[this_arg] <=0 || arg_num[this_arg] >= MyNL_ARGMAX)
          return(-print_stderr("pfprintf: Invalid positional argument number (<=0 or >=%i) %s [looktxt:pfprintf:%d]\n", 
            MyNL_ARGMAX, arg_posB[this_arg],__LINE__));
        /* get type of positional argument: follows '%' -> arg_posE[this_arg]+1 */
        fmt_pos = arg_posE[this_arg]+1;
        fmt_pos[0] = lk_tolower(fmt_pos[0]);
        if (!strchr(printf_formats, fmt_pos[0]))
          return(-print_stderr("pfprintf: Invalid positional argument type (%c != expected %c) [looktxt:pfprintf:%d]\n", 
            fmt_pos[0], fmt_args[arg_num[this_arg]-1],__LINE__));
        if (fmt_pos[0] == 'l' && (fmt_pos[1] == 'i' || fmt_pos[1] == 'd')) fmt_pos++;
        arg_posT[this_arg] = fmt_pos;
        /* get next argument... */
        this_arg++;
      }
      else
      {
        if  (tmp[1] != '%')
          return(-print_stderr("pfprintf: Must use only positional arguments (%s) [looktxt:pfprintf:%d]\n", 
            arg_posB[this_arg],__LINE__));
        else fmt_pos = arg_posB[this_arg]+2;  /* found %% */
      }
    } else
      break;  /* no more % argument */
  }
  arg_max = this_arg;
  /* get arguments from va_arg list, according to their type */
  va_start(ap, fmt_args);
  for (this_arg=0; this_arg<strlen(fmt_args); this_arg++)
  {

    switch(lk_tolower(fmt_args[this_arg]))
    {
      case 's':                       /* string */
              arg_char[this_arg] = va_arg(ap, char *);
              break;
      case 'd':
      case 'i':
      case 'c':                      /* int */
              arg_int[this_arg] = va_arg(ap, int);
              break;
      case 'l':                       /* long int */
              arg_long[this_arg] = va_arg(ap, long int);
              break;
      case 'f':
      case 'g':
      case 'e':                      /* double */
              arg_double[this_arg] = va_arg(ap, double);
              break;
      default: print_stderr("pfprintf: Argument type is not implemented (arg %%%i$ type %c) [looktxt:pfprintf:%d]\n", 
        this_arg+1, fmt_args[this_arg],__LINE__);
    }
  }
  va_end(ap);
  /* split fmt string into bits containing only 1 argument */
  fmt_pos = fmt;
  for (this_arg=0; this_arg<arg_max; this_arg++)
  {
    char *fmt_bit=NULL;
    int   arg_n;

    if (arg_posB[this_arg]-fmt_pos>0)
    {
      fmt_bit = (char*)malloc(arg_posB[this_arg]-fmt_pos+10);
      if (!fmt_bit) return(-print_stderr("pfprintf: Not enough memory [looktxt:pfprintf:%d]\n",__LINE__));
      strncpy(fmt_bit, fmt_pos, arg_posB[this_arg]-fmt_pos);
      fmt_bit[arg_posB[this_arg]-fmt_pos] = '\0';
      fprintf(f, "%s", fmt_bit); /* fmt part without argument */
    } else
    {
      fmt_bit = (char*)malloc(10);
      if (!fmt_bit) return(-print_stderr("pfprintf: Not enough memory [looktxt:pfprintf:%d]\n",__LINE__));
    }
    arg_n = arg_num[this_arg]-1; /* must be >= 0 */
    strcpy(fmt_bit, "%");
    strncat(fmt_bit, arg_posE[this_arg]+1, arg_posT[this_arg]-arg_posE[this_arg]);
    fmt_bit[arg_posT[this_arg]-arg_posE[this_arg]+1] = '\0';

    switch(lk_tolower(fmt_args[arg_n]))
    {
      case 's': fprintf(f, fmt_bit, arg_char[arg_n]);
                break;
      case 'd':
      case 'i':
      case 'c':                      /* int */
              fprintf(f, fmt_bit, arg_int[arg_n]);
              break;
      case 'l':                       /* long */
              fprintf(f, fmt_bit, arg_long[arg_n]);
              break;
      case 'f':
      case 'g':
      case 'e':                       /* double */
              fprintf(f, fmt_bit, arg_double[arg_n]);
              break;
    }
    fmt_pos = arg_posT[this_arg]+1;
    if (this_arg == arg_max-1)
    { /* add eventual leading characters for last parameter */
      if (fmt_pos < fmt+strlen(fmt))
        fprintf(f, "%s", fmt_pos);
    }
    if (fmt_bit) free(fmt_bit);

  }
  return(this_arg);
} /* pfprintf */

/*****************************************************************************
* fileparts_init: Initialize a zero fileparts structure
*****************************************************************************/
struct fileparts_struct fileparts_init(void)
{
  struct fileparts_struct parts;

  parts.FullName  = NULL;
  parts.Path      = NULL;
  parts.Name      = NULL;
  parts.Extension = NULL;

  return(parts);
} /* fileparts_init */

/*****************************************************************************
* fileparts: Split a fully qualified file name/path into pieces
*     Returns a zero structure if called with NULL argument.
*     Returns: fields are non NULL if they exist
*       Path is NULL if no Path
*       Name is NULL if just a Path
*       Extension is "" if just a dot
*****************************************************************************/
struct fileparts_struct fileparts(char *name)
{
  struct fileparts_struct parts;

  parts = fileparts_init();

  if (name) {
    char *dot_pos    = NULL;
    char *path_pos   = NULL;
    char *end_pos    = NULL;
    char *name_pos   = NULL;
    size_t  dot_length = 0;
    size_t  path_length= 0;
    size_t  name_length= 0;

    parts.FullName  = str_dup(name);
    /* extract path+filename+extension from full filename */

    if (strlen(name) == 0) return(parts);

    end_pos = name+strlen(name);  /* end of file name */

    /* extract path: searches for last file separator */
    path_pos= strrchr(name, LK_PATHSEP_C);  /* last PATHSEP */
    
    parts.Path = str_dup("");

    if (!path_pos) {
      path_pos   =name;
      path_length=0;
      name_pos   =name;
    } else {
      name_pos    = path_pos+1;
      path_length = name_pos - name;  /* from start to path+sep */
      if (path_length) {
        parts.Path = str_free(parts.Path);
        parts.Path = str_cat(name, LK_PATHSEP_S, NULL);
        strncpy(parts.Path, name, path_length);
        parts.Path[path_length]='\0';
      }
    }

    /* extract ext: now looks for the 'dot' */
    dot_pos = strrchr(name_pos, '.');           /* last dot */
    if (dot_pos > name_pos) {
      dot_length = end_pos - dot_pos;
      if (dot_length > 0) {
        parts.Extension = str_dup(name);
        strncpy(parts.Extension, dot_pos+1, dot_length);  /* skip the dot */
        parts.Extension[dot_length]='\0';
      }
    } else dot_pos = end_pos;

    /* extract Name (without extension) */
    name_length = dot_pos - name_pos; /* from path to dot */
    if (name_length) {
      parts.Name = str_dup(name);
      strncpy(parts.Name, name_pos, name_length);
      parts.Name[name_length]='\0';
    }
  } /* if (name) */
  return (parts);
} /* fileparts */

/*****************************************************************************
* fileparts_free: Free a fileparts_struct fields
*****************************************************************************/
struct fileparts_struct fileparts_free(struct fileparts_struct parts)
{
  parts.FullName = str_free(parts.FullName);
  parts.Path     = str_free(parts.Path);
  parts.Name     = str_free(parts.Name);
  parts.Extension= str_free(parts.Extension);
  
  return(parts);
}

/*****************************************************************************
* fileparts_fullname: builds a valid file name=Path+File+Ext from file parts
*****************************************************************************/
char* fileparts_fullname(struct fileparts_struct parts)
{
  char  *FullName=NULL;
  if (!parts.Extension)
    FullName = str_cat(parts.Path, strlen(parts.Path) ? LK_PATHSEP_S : "", parts.Name, NULL);
  else
    FullName = str_cat(parts.Path, strlen(parts.Path) ? LK_PATHSEP_S : "", parts.Name, ".", parts.Extension, NULL);
  return(FullName);
}

/*****************************************************************************
* try_open_target: Try to open a target file for writing and close it.
*     First test at the original location, then with getcwd current dir
*     For each possibility, first tries a stat for existence
*     Returns fully qualified target file name or NULL (error)
*****************************************************************************/
char *try_open_target(struct fileparts_struct parts, char force)
{
  char  *FullName=NULL;
  struct stat stfile;
  char   cwd[1024];
  FILE  *fid=NULL;

  /* starts with specified Path */
  FullName = fileparts_fullname(parts);

  if (!FullName || !strlen(FullName)) return(NULL);

  if (!force) {
    if (stat(FullName, &stfile) == 0) {
      print_stderr(
        "Warning: Target file '%s' already exists.\n"
        "         Use --force or --append option to override [looktxt:try_open_target:path:%d]\n",
        FullName,__LINE__);
      FullName=str_free(FullName);
      return(NULL);
    }
  }

  fid = fopen(FullName, "wb");
  if (fid) {
    fclose(fid); fid=NULL;
    return(FullName);/* OK, return */
  }
  /* now tries with local Path=getcwd() */
  FullName=str_free(FullName);
  if (!
#if defined(WIN32) || defined(_WIN64)
    _getcwd(cwd, 1024)
#else
    getcwd(cwd, 1024)
#endif
  ) strcpy(cwd, "");
  parts.Path = str_free(parts.Path); 
  parts.Path = str_dup(strlen(cwd) ? cwd : ".");
  FullName = fileparts_fullname(parts);

  if (!FullName || !strlen(FullName)) return(NULL);

  if (!force) {
    if (stat(FullName, &stfile) == 0) {
      print_stderr(
        "Warning: Target file '%s' already exists.\n"
        "         Use --force or --append option to override [looktxt:try_open_target:local:%d]\n",
        FullName,__LINE__);
      FullName=str_free(FullName);
      return(NULL);
    }
  }

  fid = fopen(FullName, "wb");
  if (fid) {
    fclose(fid); fid=NULL;
    return(FullName);
  }
  FullName=str_free(FullName);
  return(NULL);
} /* try_open_target */

/* structure initializers ************************************************* */

/*****************************************************************************
* format_rep_section: Replaces aliases names in format (data part)
*****************************************************************************/
char *format_rep_data(char *format_const)
{ /* BeginData EndData */
  char *format=NULL;

  if (!format_const) return(NULL);
  format = (char *)mem(strlen(format_const)+1);
  if (!format) exit(print_stderr( "Error: Insufficient memory [looktxt:format_rep_data:%d]\n",__LINE__));
  strcpy(format, format_const);
  if (strlen(format_const)) {
    str_rep(format, "%SEC", "%1$s"); /* Section */
    str_rep(format, "%PAR", "%1$s"); /* Parent */
    str_rep(format, "%TIT", "%2$s"); /* Title */
    str_rep(format, "%NAM", "%3$s"); /* Name */
    str_rep(format, "%ROW", "%4$d"); /* #row */
    str_rep(format, "%COL", "%5$d"); /* #columns */
    str_rep(format, "%BAS", "%6$s"); /* base name  */
    str_rep(format, "%ROT", "%6$s"); /* root name */
  }

  return(format);
} /* format_rep_data */

/*****************************************************************************
* format_rep_section: Replaces aliases names in format (section part)
*****************************************************************************/
char *format_rep_section(char *format_const)
{ /* BeginSection EndSection */
  char *format=NULL;

  if (!format_const) return(NULL);
  format = (char *)mem(strlen(format_const)+1);
  if (!format) exit(print_stderr( "Error: Insufficient memory [looktxt:format_rep_section:%d]\n",__LINE__));
  strcpy(format, format_const);
  if (strlen(format_const)) {
    str_rep(format, "%BAS", "%1$s"); /* base name */
    str_rep(format, "%PAR", "%1$s"); /* Parent */
    str_rep(format, "%ROT", "%1$s"); /* root name */
    str_rep(format, "%SEC", "%2$s"); /* Section */
    str_rep(format, "%NAM", "%3$s"); /* Name */
    str_rep(format, "%TIT", "%3$s"); /* Title */
  }
  return(format);
} /* format_rep_section */

/*****************************************************************************
* format_rep_tag: Replaces aliases names in format (tag part)
*****************************************************************************/
char *format_rep_tag(char *format_const)
{ /* AssignTag */
  char *format=NULL;

  if (!format_const) return(NULL);
  format = str_dup(format_const);
  if (strlen(format_const)) {
    str_rep(format, "%BAS", "%1$s"); /* base name  */
    str_rep(format, "%PAR", "%1$s"); /* Parent */
    str_rep(format, "%ROT", "%1$s"); /* root name  */
    str_rep(format, "%SEC", "%2$s"); /* Section */
    str_rep(format, "%NAM", "%3$s"); /* Name */
    str_rep(format, "%VAL", "%4$s"); /* Value (string) */
  }
  return(format);
} /* format_rep_tag */

/*****************************************************************************
* format_rep_header: Replaces aliases names in format (header/footer part)
*****************************************************************************/
char *format_rep_header(char *format_const)
{ /* Header Footer */
  char *format=NULL;

  if (!format_const) return(NULL);
  format = str_dup(format_const);
  if (strlen(format_const)) {
    str_rep(format, "%FMT", "%1$s"); /* format */
    str_rep(format, "%USR", "%2$s"); /* user name */
    str_rep(format, "%CMD", "%3$s"); /* command */
    str_rep(format, "%SRC", "%4$s"); /* source file */
    str_rep(format, "%TIT", "%4$s"); /* title */
    str_rep(format, "%FIL", "%4$s"); /* filename */
    str_rep(format, "%SIZ", "%5$d"); /* file size */
    str_rep(format, "%TIM", "%6$s"); /* file time */
    str_rep(format, "%TXT", "%7$s"); /* target text file */
    str_rep(format, "%BIN", "%8$s"); /* target binary file */
    str_rep(format, "%BAS", "%9$s"); /* base name */
    str_rep(format, "%PAR", "%9$s"); /* parent */
    str_rep(format, "%NAM", "%9$s"); /* name */
    str_rep(format, "%ROT", "%9$s"); /* root name */
    str_rep(format, "%DATE", "%10$s"); /* date */
    str_rep(format, "%DATL", "%11$d"); /* date as a long */
  }

  return(format);
} /* format_rep_header */

/*****************************************************************************
* format_rep_binref: Replaces aliases names in format (bin ref part)
*****************************************************************************/
char *format_rep_binref(char *format_const)
{ /* BinReference */
  char *format=NULL;

  if (!format_const) return(NULL);
  format = str_dup(format_const);
  if (strlen(format_const)) {
    str_rep(format, "%FIL", "%1$s"); /* source file */
    str_rep(format, "%BEG", "%2$d"); /* binary block start */
    str_rep(format, "%END", "%3$d"); /* binary block stop */
    str_rep(format, "%LEN", "%4$d"); /* binary block length */
    str_rep(format, "%ROW", "%5$d"); /* #rows */
    str_rep(format, "%COL", "%6$d"); /* #columns */
  }
  return(format);
} /* format_rep_binref */

/*****************************************************************************
* format_init: Sets an output format matching request
*****************************************************************************/
struct format_struct format_init(struct format_struct formats[], char *request)
{
  int   i;
  int   i_format=-1;
  char *tmp=NULL;
  struct format_struct format;  /* return value */

  /* get the format to lower case */
  if (!request || !strlen(request)) i_format=0;
  else {
    char *request_lower=NULL;
    char ntmp[256];

    request_lower = str_lowup(str_dup(request), 'l');

    /* look for a specific format in formats.Name table */
    for (i=0; i < NUMFORMATS; i++)
    {
      if (!formats[i].Name || !strlen(formats[i].Name)) continue;
      strncpy(ntmp, formats[i].Name, 256);
      str_lowup(ntmp, 'l');
      if (strstr(request_lower, ntmp) || strstr(ntmp, request_lower) || !strcmp(request_lower, formats[i].Extension)) { i_format = i; break; }
    }
    request_lower=str_free(request_lower);
  }
  if (i_format < 0)
  {
    i_format = 0; /* default format is #0 */
    print_stderr( "Warning: Unknown output format '%s'. Using %s [looktxt:format_init:%d]\n", 
      request, formats[i_format].Name,__LINE__);
    if (formats[i_format].Name == NULL) exit(EXIT_FAILURE);
  }
  format = formats[i_format];
  if (request && strstr(request,"binary"))
    tmp = str_cat(format.Name, " binary double data", NULL);
  else tmp = str_dup(format.Name);
  /* change pointer location for new name */
  format.Name = tmp;

  /* Replaces vfprintf parameter name aliases */
  /* Header Footer */
  format.Header       = format_rep_header(format.Header);
  format.Footer       = format_rep_header(format.Footer);
  /* AssignTag */
  format.AssignTag    = format_rep_tag(format.AssignTag);
  /* BeginSection EndSection */
  format.BeginSection = format_rep_section(format.BeginSection);
  format.EndSection   = format_rep_section(format.EndSection);
  /*  BeginData  EndData  */
  format.BeginData    = format_rep_data(format.BeginData  );
  format.EndData      = format_rep_data(format.EndData    );
  format.BinReference = format_rep_binref(format.BinReference);

  return(format);
} /* format_init */

/*****************************************************************************
* format_free: free format structure
*****************************************************************************/

struct format_struct format_free(struct format_struct format)
{
/* free format specification strings */
  format.Name        =str_free(format.Name        );
  format.Header      =str_free(format.Header      );
  format.Footer      =str_free(format.Footer      );
  format.AssignTag   =str_free(format.AssignTag   );
  format.BeginSection=str_free(format.BeginSection);
  format.EndSection  =str_free(format.EndSection  );
  format.BeginData   =str_free(format.BeginData   );
  format.EndData     =str_free(format.EndData     );
  format.BinReference=str_free(format.BinReference);
  return(format);
} /* format_free */

/*****************************************************************************
* strlist_init: init a zero strlist structure with new slots
*****************************************************************************/
struct strlist_struct strlist_init(char *name)
{
  struct strlist_struct list;
  int i;

  list.length = 0;
  list.nalloc= ALLOC_BLOCK;
  list.List  = (char  **)mem(list.nalloc*sizeof(char *));
  if(list.List == NULL) {
      print_stderr( "Error: Memory exhausted during allocation of size %ld for '%s' [looktxt:strlist_init:%d].", 
        (list.nalloc)*sizeof(char*), name,__LINE__);
      exit(EXIT_FAILURE);
    }
  strncpy(list.Name, name && strlen(name) ? name : "", 32);
  for (i=0; i<list.nalloc; list.List[i++]=NULL);
  return(list);
}  /* strlist_init */

/*****************************************************************************
* strlist_free: Free all list elements
*****************************************************************************/
struct strlist_struct strlist_free(struct strlist_struct list)
{
  if (list.List && list.nalloc) {
    long index;
    for (index=0; index < list.nalloc; index++) {
      str_free(list.List[index]);
    }
  }
  list.length=list.nalloc=0;
  list.List=(char**)memfree(list.List);
  return(list);
} /* strlist_free */

/*****************************************************************************
* options_init: Set default options values
*****************************************************************************/
struct option_struct options_init(char *pgname)
{
  struct option_struct options;

  options.pgname = str_dup(pgname ? pgname : "looktxt");

  options.sources_nb = 0;
  options.use_struct = 0;
  options.use_binary = 0;
  options.catenate   = 0;
  options.force      = 0;
  options.out_table  = 0;
  options.out_headers= 0;
  options.verbose    = 1;
  options.test       = 0;
  options.file_index = 0;
  options.fortran    = 1;
  options.nelements_min=0;
  options.nelements_max=0;
  options.names_length =32;
  options.names_lowup= 0;
  options.names_root = NULL;
  options.fast       = 0;
  options.outfile    = fileparts_init();
  options.sections   = strlist_init("sections");
  options.metadata   = strlist_init("metadata");
  options.metadata_only=0;
  options.makerows   = strlist_init("makerows");
  options.openmode   = str_dup("wb");
  options.separator  = str_dup(Cseparator);
  options.comment    = str_dup(Ccomment);
  options.eol        = str_dup(Ceol);
  options.option_list= NULL;
  options.ismatnexus = 0;
  options.format     = format_init(Global_Formats,
    getenv("LOOKTXT_FORMAT") ? getenv("LOOKTXT_FORMAT") : LOOKTXT_FORMAT);
  options_warnings   = 100; /* shows this number of warnings at most */
  return(options);
} /* options_init*/

/*****************************************************************************
* options_free: Free options values
*****************************************************************************/
struct option_struct options_free(struct option_struct options)
{
  options.outfile =fileparts_free(options.outfile);
  options.sections=strlist_free(options.sections);
  options.metadata=strlist_free(options.metadata);
  options.makerows=strlist_free(options.makerows);
  options.format  =format_free(options.format);

  options.separator  =str_free(options.separator);
  options.comment    =str_free(options.comment);
  options.eol        =str_free(options.eol);
  options.option_list=str_free(options.option_list);
  options.pgname     =str_free(options.pgname);
  options.openmode   =str_free(options.openmode);
  options.names_root =str_free(options.names_root);
  return(options);
} /* options_free*/

/*****************************************************************************
* file_init: init a zero file_struct
*****************************************************************************/
struct file_struct file_init(void)
{
  struct file_struct file;  /* will be the return value */

  file.Source    = NULL;    /* zero structure */
  file.TargetTxt = NULL;
  file.TargetBin = NULL;
  file.SourceHandle= NULL;
  file.TxtHandle = NULL;
  file.BinHandle = NULL;
  file.Path      = NULL;
  file.SourceName= NULL;
  file.TargetName= NULL;
  file.Extension = NULL;
  file.RootName  = NULL;
  file.Size = 0;
  file.Time = 0;
#ifdef USE_MAT
  file.mxRoot    = NULL;
  file.mxData    = NULL;
  file.mxHeaders = NULL;
#endif
#ifdef USE_NEXUS
  file.nxHandle = NULL;
#endif

  return(file);
} /* file_init */

/*****************************************************************************
* file_close: Close a source file and clear allocated memory
*****************************************************************************/
struct file_struct file_close(struct file_struct file)
{
  if (file.SourceHandle) { 
    if(fclose(file.SourceHandle)) 
      print_stderr( "Warning: Could not close input Source file %s [looktxt:file_close:%d]\n",
        file.Source,__LINE__); 
    file.SourceHandle=NULL; 
  }

  file.Source    =str_free(file.Source);
  file.TargetTxt =str_free(file.TargetTxt);
  file.TargetBin =str_free(file.TargetBin);
  file.Path      =str_free(file.Path);
  file.SourceName=str_free(file.SourceName);
  file.TargetName=str_free(file.TargetName);
  file.Extension =str_free(file.Extension);
  file.RootName  =str_free(file.RootName);
#ifdef USE_MAT
#ifndef USE_MEX /* do not free in MeX mode */
  if (file.mxData)    mxDestroyArray(file.mxData);
  if (file.mxHeaders) mxDestroyArray(file.mxHeaders);
  if (file.mxRoot)    mxDestroyArray(file.mxRoot); 
#endif
  file.mxRoot = file.mxData = file.mxHeaders = NULL; 
#endif
  return(file);
}

/*****************************************************************************
* file_open: Open a source file structure
*     determine file parts, set target names and test for existence
*     returns: a source file structure
*       Source       is NULL in case of open error
*       TargetTxt    is NULL in case of target text creation error (exists)
*       TargetBin    is NULL in case of target binary creation error (exists)
*****************************************************************************/
struct file_struct file_open(char *name, struct option_struct options)
{
  struct file_struct file;  /* will be the return value */
  char  *root=NULL;

  file = file_init();

  if (name && strlen(name))
  {
    struct fileparts_struct parts;
    struct stat stfile;

    /* extracts source file parts */
    parts = fileparts(name);
    if (parts.Path)       file.Path      = str_dup(strlen(parts.Path) ? parts.Path: ".");
    if (parts.Name)       file.SourceName= str_dup(parts.Name);
    if (parts.Extension)  file.Extension = str_dup(parts.Extension);
    file.Source= str_dup(name);
    parts=fileparts_free(parts);

    /* get info about source file */
    if (stat(file.Source, &stfile) == 0) {
      file.Size = stfile.st_size;
      file.Time = stfile.st_mtime;
    } else {
      print_stderr( "Error: Source file '%s' can not be accessed [looktxt:file_open:%d]\n", 
        file.Source,__LINE__);
      file.Source = str_free(file.Source); 
      return(file);
    }

    /* opens source file (for reading) */
    file.SourceHandle = fopen(file.Source, "rb");
    if (!file.SourceHandle) {
      print_stderr( "Error: Source file '%s' can not be opened for reading [looktxt:file_open:%d]\n", 
        file.Source,__LINE__);
      file.Source = str_free(file.Source);
      return(file);
    }
    /* sets default output name */
    if (file.Extension && strlen(file.Extension))
      parts.Name      = str_cat(file.SourceName, "_", file.Extension, NULL);
    else
      parts.Name      = str_dup(file.SourceName);
    parts.Path     = str_dup(file.Path);
    parts.Extension= str_dup(options.format.Extension);

    /* handle user target name option or set to default */
    if (options.outfile.FullName) {
      if (options.outfile.Name) {
        if (strcmp(options.outfile.Name,"*")) { /* not '*.ext' */
          str_free(parts.Name); parts.Name=NULL;
          if (options.file_index > 1) { /* catenate file index */
            char chr_index[256];
            sprintf(chr_index, "_%ld\0", options.file_index);
            parts.Name      = str_cat(options.outfile.Name, chr_index, NULL);
          } else parts.Name = str_dup(options.outfile.Name);
        }
      }
      if (options.outfile.Path) {
        parts.Path=str_free(parts.Path); 
        parts.Path=str_dup(options.outfile.Path);
      }
      if (options.outfile.Extension && strlen(options.outfile.Extension)) {
        parts.Extension=str_free(parts.Extension);
        parts.Extension=str_dup(options.outfile.Extension);
      }
    }

    /* check stdout/stderr output */
    if (options.outfile.FullName
    && (!strcmp(options.outfile.FullName, "stdout")
        || !strcmp(options.outfile.FullName, "-"))) {
      file.TargetTxt = str_dup("stdout");
      if (options.use_binary && options.verbose >= 1) 
        print_stderr("Warning: File '%s': Can not use binary target file with stdout output [looktxt:file_open:%d]\n"
                      "         Using TXT output.\n", 
          file.Source,__LINE__);
      options.use_binary = 0;
    } else if (options.outfile.FullName
    && !strcmp(options.outfile.FullName, "stderr")) {
      file.TargetTxt = str_dup("stderr");
      if (options.use_binary && options.verbose >= 1) 
        print_stderr("Warning: File '%s': Can not use binary target file with stderr output [looktxt:file_open:%d]\n"
               "         Using TXT output.\n", 
          file.Source,__LINE__);
      options.use_binary = 0;
    } else
#ifdef USE_MEX
    if (options.ismatnexus == 3)
      file.TargetTxt = str_dup("mex");
    else
#endif
      file.TargetTxt = options.test ? 
        fileparts_fullname(parts) : try_open_target(parts, options.force);

    if (options.verbose >= 2) 
      printf("VERBOSE[file_open]:         file '%s': target TXT %s", 
        file.Source, file.TargetTxt);
    if (!file.TargetTxt) {
      print_stderr("ERROR: Invalid Target: outfile=%s parts=%s/%s.%s\n", 
        options.outfile.FullName ? options.outfile.FullName : "NULL",
        parts.Path ? parts.Path : "", parts.Name, parts.Extension);
      file    = file_close(file);
      options = options_free(options);
      exit(EXIT_FAILURE);
    }

    /* handle binary output file */
    if (options.use_binary) { /* only change extension */
      parts.Extension = str_free(parts.Extension);
      parts.Extension = str_dup("bin");
      file.TargetBin = options.test ? 
        fileparts_fullname(parts) : try_open_target(parts, options.force);
      if (options.verbose >= 2) printf(" BIN %s", file.TargetBin);
    }
    if (options.verbose >= 2) printf("\n");

   /* init ROOT Name based on file name and names_root */
    if (!options.names_root) {
      root = str_valid(parts.Name, options.names_length);
    } else if (!strcmp(options.names_root, "NULL"))
      root = NULL;                           /* no ROOT */
    else root = str_valid(options.names_root, options.names_length); /* user ROOT */

    parts=fileparts_free(parts);

    file.RootName = ( root ? str_valid(root, 0) : str_dup("") );
    if (!strncmp(file.RootName, "lk_", 3) && options.verbose >= 1)
      print_stderr( "Warning: Data root level renamed as %s (started with number).\n"
                    "         Output file names are unchanged [looktxt:file_open:%d]\n",
        file.RootName,__LINE__);
    root=str_free(root);

  } /* if (name is non NULL) */
  return(file);
} /* file_open */

/* lists functions ******************************************************** */

/*****************************************************************************
* strlist_print: Prints the content of the strlist. Returns length.
*****************************************************************************/
long strlist_print(struct strlist_struct list)
{

  print_stderr("List '%s' contains %ld elements\n", list.Name, list.length);
  if (!list.length  | !list.nalloc) {
    print_stderr("  Empty list\n");
  } else {
    long index;
    for (index=0; index < list.length; index++)
    print_stderr("  List[%ld]='%s'\n", index, list.List[index]);
  }

  return(list.length);
} /* strlist_print */


/*****************************************************************************
* strlist_add: Add a copy of a char* element to a strlist_struct
*     reallocates if the list is not long enough
*****************************************************************************/
struct strlist_struct strlist_add(struct strlist_struct *list, char *element)
{

  if (!element) return(*list);

  if (list->length  >= list->nalloc) {
    /* increase list size by new element slots */
    char **p=NULL;
    int    i;
    list->nalloc = list->length+ALLOC_BLOCK;
    p = (char **)realloc(list->List, list->nalloc*sizeof(char*));
    if(p == NULL) {
      print_stderr( "Error: Memory exhausted during re-allocation of size %ld for '%s' [looktxt:strlist_add:%d].", 
        (list->nalloc)*sizeof(char*), list->Name,__LINE__);
      exit(EXIT_FAILURE);
    }
    list->List   = (char **)p;
    for (i=list->length; i<list->nalloc; list->List[i++]=NULL);
  }

  /* store element location when it exists */
  list->List[list->length] = str_dup(element);
  list->length++;

  return(*list);
} /* strlist_add */

/*****************************************************************************
* strlist_add_void: same as strlist_add but with any type of element
*****************************************************************************/
struct strlist_struct strlist_add_void(struct strlist_struct *list, void *element)
{

  if (!element) return(*list);

  if (list->length  >= list->nalloc) {
    /* increase list size by new element slots */
    char **p=NULL;
    int    i;
    list->nalloc = list->length+ALLOC_BLOCK;
    p = (char **)realloc(list->List, list->nalloc*sizeof(char*));
    if(p == NULL) {
      print_stderr( "Error: Memory exhausted during re-allocation of size %ld for '%s' [looktxt:strlist_add:%d].", 
        (list->nalloc)*sizeof(char*), list->Name,__LINE__);
      exit(EXIT_FAILURE);
    }
    list->List   = (char **)p;
    for (i=list->length; i<list->nalloc; list->List[i++]=NULL);
  }

  /* store element location when it exists */
  list->List[list->length] = element;
  list->length++;

  return(*list);
} /* strlist_add_void */

/*****************************************************************************
* strlist_search: Search for an element in a str list
*     returns first matched element index, or -1
*****************************************************************************/
int strlist_search(struct strlist_struct list, char *element)
{
  long  index;
  if (!list.List || !list.nalloc || !list.length || !element) return(-1);
  for (index=0; index < list.length; index++) {
    if (list.List[index] && strstr(list.List[index], element) != NULL) return(index);
  }
  return(-1);
} /* strlist_search */

/******************************************************************************
* data_init: Set a zero data_struct
*****************************************************************************/
struct data_struct data_init(void)
{
  struct data_struct field;

  field.index   = 0;
  field.Name    = NULL;
  field.Name_valid    = NULL;
  field.Header  = NULL;
  field.Section = NULL;
  field.rows    = 0;
  field.columns = 0;
  field.n_start = 0;
  field.n_end   = 0;
  field.c_start = 0;
  field.c_end   = 0;

  return(field);
} /* data_init */

/******************************************************************************
* data_print: Prints a data_struct
*****************************************************************************/
void data_print(struct data_struct field)
{
  print_stderr("Data field %li '%s.%s' (%s)\n", 
    field.index, field.Section, field.Name, field.Name_valid );
  print_stderr("  size=[%li x %li]\n", field.rows, field.columns);
  print_stderr("  numeric=[%li:%li]\n", field.n_start, field.n_end);
  print_stderr("  comment=[%li:%li]\n", field.c_start, field.c_end);
  print_stderr("  header='%s'\n", field.Header);
} /* data_print */

/*****************************************************************************
* data_free: Free a data_struct
*****************************************************************************/
struct data_struct data_free(struct data_struct field)
{
  field.Name      =str_free(field.Name);
  field.Name_valid=str_free(field.Name_valid);
  field.Header    =str_free(field.Header);
  field.Section   =str_free(field.Section);
  field.rows=0;
  return(field);
} /* data_free */

/*****************************************************************************
* data_get_char: Read in file, allocate and read the char part
*****************************************************************************/
char *data_get_char(struct file_struct file, size_t start, size_t end)
{
  char *string=NULL;
  if      (start < 0) start=0;
  else if (start)     start=start-1;
  if (end >= file.Size) end=file.Size;
  if (start >  end)       return (NULL);
  if (!file.SourceHandle) return (NULL);
  string = mem(end - start + 2);
  if(fseek(file.SourceHandle, start, SEEK_SET))
    print_stderr( "Warning: Error in fseek(%s,%i) [looktxt:data_get_char:%d]\n",
      file.Source, start,__LINE__);
  if (fread(string, 1, end-start, file.SourceHandle) < end-start)
    print_stderr( "Warning: Error in fread(%s,%i) [looktxt:data_get_char:%d]\n",
      file.Source, end-start+1,__LINE__);
  string[end-start+1] = '\0';

  return(string);
} /* data_get_char */

/*****************************************************************************
* data_get_line: Read in file, allocate and read the full char line part
*****************************************************************************/
char *data_get_line(struct file_struct file, long *start)
{
  char string[64*MAX_LENGTH];

  if (!start)             return (NULL);
  if (!file.SourceHandle) return (NULL);
  if (*start < 0) *start=0;
  if (*start >= file.Size)return(NULL);

  if (fseek(file.SourceHandle, *start, SEEK_SET))
    print_stderr( "Warning: Error in fseek(%s,%i) [looktxt:data_get_line:%d]\n",
      file.Source, *start,__LINE__);
    if (!fgets(string, 64*MAX_LENGTH, file.SourceHandle))
      print_stderr( "Warning: Error in fgets(%s,%i) [looktxt:data_get_line:%d]\n",
      file.Source, 64*MAX_LENGTH,__LINE__);
  *start = ftell(file.SourceHandle);

  return(str_dup_n(string, 64*MAX_LENGTH));
} /* data_get_line */

/*****************************************************************************
* data_get_double: Read in file, allocate and read 'double' part
*****************************************************************************/
double *data_get_double(struct file_struct file, struct data_struct field, struct option_struct options)
{
  double *data=NULL;
  
/* two hard coded methods for reading numerical values */
/* 0: fast but requires isspace for numerical separators (sscanf) */
/* 1: slightly slower, but can handle separator                    */
  if (!field.rows || !field.columns || !file.Source) return (NULL);
  if (field.n_start > field.n_end) return (NULL);
  if (!file.SourceHandle)          return (NULL);

  data = (double*)mem(field.rows*field.columns*sizeof(double));

  if (!data) {
    print_stderr( "Error: Memory exhausted during allocation of double[%ld x %ld] [looktxt:data_get_double:%d]\n",
      field.rows, field.columns,__LINE__);
    exit(EXIT_FAILURE);
  }
  if (options.fast == 1) {
    /* fast method: fscanf */
    
    long index=0;
    if (fseek(file.SourceHandle, field.n_start-1 > 0 ? field.n_start-1 : 0, SEEK_SET))
      if (options_warnings-- > 0)
        print_stderr( "Warning: Error in fseek(%s,%i) [looktxt:data_get_double:%d]\n",
        file.Source, field.n_start-1, __LINE__);
    for (index =0; index < field.rows*field.columns; index ++) {
      long   pos = ftell(file.SourceHandle);
      double value=0;
      if (!fscanf(file.SourceHandle, "%lf", &value)) {
        if (options.verbose > 1) {
          char  *string=NULL;
          long   len=field.n_end - field.n_start;
          if (len < 0 || len > 10) len=10;

          string=data_get_char(file, pos, pos+len);
          if (options_warnings-- > 0) {
            print_stderr( "Warning: Format error when reading double[%d of %ld] '%s' at %s:%ld [looktxt:data_get_double:%d]\n",
              index, (long)(field.rows*field.columns), field.Name ? field.Name : "null", file.Source, (long)pos, __LINE__);
            print_stderr( "         '%s ...' (probably contains a non 'isspace' separator)\n", string);
            print_stderr( "         Do not use --fast if this value is important to you. Ignoring.\n", string);
          }
          if (fseek(file.SourceHandle, pos+1, SEEK_SET) && options_warnings-- > 0)
            print_stderr( "Warning: Error in fseek(%s,%i) [looktxt:data_get_double:%d]\n",
              file.Source, pos, __LINE__);
          
          string=str_free(string);
        }
      }
      data[index] = (double)value;
    } /* end for */
  } else {
    /* slower method: fread+sscanf */
    char *string   = data_get_char(file, field.n_start, field.n_end);
    char *p        = NULL;
    long  index=0;

	  if (!string) {
		  print_stderr( "Error: can not get field %s=[%ld:%ld] in file %s [looktxt:data_get_double:%d]\n",
            field.Name, field.n_start, field.n_end, file.Source, __LINE__);
		  exit(EXIT_FAILURE);
	  }
	  
	  /* replace all non digit characters by spaces, except nan and inf */
	  for (p=string; p < string+strlen(string) -1; p++) {
	    char c=lk_tolower(*p);
	    if (!strchr("0123456789e.+-naif", c)) *p=' ';
	  }
    
    /* iteratively read numeric values from the string */
    p=string;
    for (index =0; index < field.rows*field.columns; index ++) {
      char   fail=0;
      double value=0;
      
      /* read the next number */
      if (!sscanf(p, " %lf ", &value)) fail  = 1;
      data[index] = (double)value;
      
      /* search for next separator */
      if ((p = strchr(p, ' ')) == NULL) fail = 1;
      /* then next digit */
      while (p && p < string+strlen(string) -1 && !strchr("0123456789e.+-naif", lk_tolower(*p))) {
	      p++;
	    }
      
      if (fail && options_warnings-- > 0 && options.verbose > 1) {
		    print_stderr( "Warning: Format error when reading double[%d of %ld] '%s' at %s [looktxt:data_get_double:%d]\n",
            index, (long)(field.rows*field.columns), field.Name ? field.Name : "null", file.Source,__LINE__);
        if (!p) break;
	    }
        
    }
    string = str_free(string);

  }
  
  return(data);
} /* data_get_double */

/*****************************************************************************
* table_init: Sets a zero table_struct
*****************************************************************************/
struct table_struct *table_init(char *name)
{
  struct table_struct *table=malloc(sizeof(struct table_struct));
  int i;

  table->length= 0;
  table->nalloc= ALLOC_BLOCK;
  table->Name  = name ? str_dup(name) : NULL;
  table->List  = (struct data_struct *)mem(table->nalloc*sizeof(struct data_struct));
  for (i=0; i<table->nalloc; table->List[i++] = data_init());

  return(table);
} /* table_init */

/*****************************************************************************
* table_add: Add a data_struct element to a table_struct
*     reallocates if the list is not long enough
*****************************************************************************/
void table_add(struct table_struct *table, struct data_struct data)
{

  if (!table) return;
  if (!table->List) {
    print_stderr( "Warning: Table List pointer is NULL (index=%ld nalloc = %ld) [looktxt:table_add:%d]\n", 
      table->length, table->nalloc,__LINE__);
    return;
  }

  if (!data.rows) return;
  if (table->length  >= table->nalloc) {
    /* increase list size by new element slots */
    void *p=NULL;
    int   i;
    table->nalloc = table->length+ALLOC_BLOCK;
    p = (void *)realloc(table->List, (table->nalloc)*sizeof(struct data_struct));
    if(p == NULL) {
      print_stderr( "Error: Memory exhausted during re-allocation of table %s size %ld [looktxt:table_add:%d]\n", 
        table->Name, (table->nalloc)*sizeof(struct data_struct),__LINE__);
      exit(EXIT_FAILURE);
    }
    table->List   = (struct data_struct *)p;
    for (i=table->length; i<table->nalloc; table->List[i++] = data_init());
  }

  if (table->length >= 0) {
    table->List[table->length]=data_free(table->List[table->length]);
    table->List[table->length]=data;
    table->length++;
  }
} /* table_add */

/*****************************************************************************
* table_print: Print all table_struct elements
*****************************************************************************/
void table_print(struct table_struct table)
{
  if (table.List && table.length) {
    long i;
    for (i=0; i < table.length; i++)
      print_stderr("Table[%ld] %s.%s.%s = [%ld x %ld] '%s'\n",
        (long)table.List[i].index, table.Name, table.List[i].Section, table.List[i].Name,
        table.List[i].rows, table.List[i].columns, table.List[i].Header);
  }
} /* table_print */


/*****************************************************************************
* table_free: Free all table_struct elements
*****************************************************************************/
struct table_struct *table_free(struct table_struct *table)
{
  if (table->List && table->nalloc) {
    long index;
    for (index=0; index < table->nalloc; index++)
      data_free(table->List[index]);
  }
  table->Name=str_free(table->Name);
  table->length=table->nalloc=0;
  table->List=(struct data_struct *)memfree(table->List);
  return(table);
} /* table_free */

/* ****************************************************************************
* looktxt functions                                                          
***************************************************************************** */ 
void print_version(char *pgmname)
{ /* Show program help. pgmname = argv[0] */
  printf("%s " VERSION " (" DATE ") by " AUTHOR "\n", pgmname);
  printf("Copyright (C) 2009 Institut Laue Langevin <http://www.ill.eu/computing>\n"
         "  This is free software; see the source for copying conditions.\n"
         "  There is NO warranty; not even for MERCHANTABILITY or FITNESS\n"
         "  FOR A PARTICULAR PURPOSE. Used in iFit <http://ifit.mccode.org>.\n");
} /* print_version */

void print_usage(char *pgmname, struct option_struct options)
{ /* Show program help. pgmname = argv[0] */
  int i;
  print_version(pgmname);
  printf( "Usage: %s [options] file1 file2 ...\n", pgmname);
  printf( "Action: Search and export numerics in a text/ascii file.\n"
  "   This program analyses files looking for numeric parts\n"
  "   Each identified numeric field is named and exported\n"
  "   into an output filename, usually as a structure with fields\n"
  "     ROOT.SECTION.FIELD = VALUE\n"
  "   In order to sort your data, you may specify as many --section\n"
  "   and --metadata options as necessary\n"
  "   All character sets are supported as long as numbers have format\n"
  "     [+-][0-9].[0-9](e[+-][0-9])\n"
  "   Infinite and Not-a-Number values are also supported.\n\n"
  "Example: %s -f Matlab -s PARAM -s DATA filename\n"
  "Usual options are: --fast --binary --force --comment=NULL\n\n", pgmname);
  printf(
"Main Options are:\n"
"--binary   or -b    Stores numerical matrices into an additional binary\n"
"                    double file, which makes further import much faster.\n"
"--catenate or -c    Catenates similar numerical fields (default)\n"
"--catenate=0        Do not catenate similar fields (slower)\n"
"--force    or -F    Overwrites existing files\n"
"--format=FORMAT     Sets the output format for generated files. See below\n"
"      -f FORMAT     \n"
"--fortran --wrapped Catenates wrapped/single Fortran-style output lines with\n"
"                    previous matrices (default)\n"
"--fortran=0         Do not use Fortran compatibility mode\n"
"--headers  or -H    Extracts headers for each numerical field\n"
"--help     or -h    Show this help\n"
"--section=SEC       Classifies fields into section matching word SEC\n"
"       -s SEC\n"
"--metadata=META     Extracts lines containing word META as user meta data\n"
"        -m META\n"
"\n"
"Other Options are:\n"
"--append            Append to existing files. This also sets --force\n"
"--fast              Uses a faster reading method, requiring numerics\n"
"                    to be separated by \\n\\t\\r\\f\\v and spaces only\n"
"--makerows=NAME     All fields matching NAME are transformed into row vectors\n"
"--names_lower       Converts all names into lower characters\n"
"--names_upper       Converts all names into upper characters\n"
"--names_length=LEN  Sets the maximum length to use for names (32)\n"
"--names_root=ROOT   Sets the base name for structures to ROOT\n"
"                    Default is to use the output file name\n"
"                    Use --names_root=NULL or 0 not to use root level.\n"
"--nelements_min=MIN Only extracts numericals with at least MIN elements\n"
"--nelements_max=MAX Only extracts numericals with at most MAX elements\n"
"--outfile=FILE      Sets output file name. Extension, if missing, is added\n"
"       -o FILE      depending on the FORMAT. FILE may be stdout or stderr\n"
"--struct=CHAR       Will use CHAR as struct builder. Default is '.'\n"
"                    Use --struct=NULL or 0 not to use structures.\n"
"                    Alternatively you may use '_'.\n"
"--verbose  or -v    Displays analysis information\n"
"--version           Display looktxt version\n"
"--silent            Silent mode. Only displays errors/warnings\n"
"--test              Test mode, analyze files, but do not write any output file\n"
"--comment=COM       Sets comment characters (ignore line if at start)\n"
"--eol=EOL           Sets end-of-line characters\n"
"--separator=SEP     Sets word seperators (handled as spaces)\n"

"\n"
);
  printf( "Available output formats are (default is %s):\n  ", options.format.Name);
  for (i=0; i < NUMFORMATS; i++)
    if (Global_Formats[i].Name && strlen(Global_Formats[i].Name)) 
      printf("\"%s\" " , Global_Formats[i].Name);
  printf("\n");
#ifdef USE_MAT
  printf( "  The MATfile format is a binary Matlab derived from HDF5\n");
#endif 
  printf( "  Adding 'binary' to the FORMAT name will do the same as --binary.\n");
  printf( "  The LOOKTXT_FORMAT environment variable may set the default FORMAT to use.\n");
  exit(EXIT_SUCCESS);
} /* print_usage */

/*****************************************************************************
* file_scan: Parse input parameters starting with '-' sign (OPTIONS)
*     returns the table structure for the processed source file,
*     containing a List of data_struct
* Used by: parse_files
*****************************************************************************/
struct table_struct *file_scan(struct file_struct file, struct option_struct options)
{
  struct table_struct *table;
  table = table_init(file.RootName);

  if (file.Source && file.SourceHandle && file.TargetTxt
        && (!options.use_binary || file.TargetBin)) {
    /* source file scanning process */

    int  last_is     = Beol; /* type of preceeding char */
    int  is          = Beol; /* current char type */
    int  need        = 0; /* what is to be expected for next char */
    int  found       = 0; /* is that char expected ? */
    int  fieldend    = 0; /* flag is TRUE for end of field */
    char possiblecmt = 0; /* flag is TRUE when in a comment */
    char possiblenum = 0; /* flag is TRUE when we migth be in a number ... */
    char inpoint     = 0; /* if we are after a point */
    char inexp       = 0; /* if we are after an exp */

    long pos         = 0; /* current pos */
    size_t startcharpos= 0; /* char field start pos */
    size_t endcharpos  = 0; /* char field end pos */
    size_t startnumpos = 0; /* num field start pos */
    size_t endnumpos   = 0; /* num field end pos */
    size_t last_eolpos = 0; /* last EOL position */
    size_t last_seppos = 0; /* Separator */
    char   isNAN       = 0, isINF=0;
    char   sNAN[]      = "nan";
    char   sINF[]      = "inf";

    long rows        = 0; /* number of rows in matrix */
    long columns     = 0; /* number of columns in matrix */
    long last_columns= 0; /* to test if number of columns has changed since last line */

    long fieldindex  = 0; /* the current field index */

    /* events for num search                 {n,a,p,l,e,s,c,s} */
    const long needforstartnum =  Bnumber + Bpoint + Bsign;
    const long needafternumber =  Bnumber + Bpoint + Bexp + Beol + Bseparator;
    const long needaftersign   =  Bnumber + Bpoint;
    const long needafterexp    =  Bnumber + Bsign;
    const long needafterpoint  =  Bnumber + Bexp   + Beol + Bseparator;
        /* but Bnumber only, if num started with point ! */
    const long needaftereol    =  Bnumber + Bpoint + Bsign + Beol + Bseparator;
    const long needaftersep    =  Bnumber + Bpoint + Bsign + Beol + Bseparator;

    char c;
    
    time_t StartTime       =0;
    time_t EndTime         =0;
    
    time(&StartTime); /* compute starting time */
    
    if (options.verbose >= 2)
      printf("VERBOSE[file_scan]: Scanning file %s [0-%ld] ...\n", file.Source, (long)file.Size);

    do {
      c = lk_tolower(getc(file.SourceHandle));
      
      last_is = is;
      if (c == EOF) { /* end of file reached : exit */
        last_eolpos = file.Size;
        last_seppos = file.Size;
        last_is     = Beol;
        possiblecmt = 0;
        need        = 0; /* generates end of field : end of line */
      }
      is =   Bnumber    * (lk_isdigit(c) != 0)
        + Balpha     * (lk_isprint(c) != 0)
        + Bpoint     * (c == '.')
        + Beol       * (c == '\n' || c == '\f')
        + Bexp       * (c == 'e' && possiblenum)
        /* must be in a number field */
        + Bsign      *((c == '-' || c == '+') && (last_is & (Bexp | Bseparator | Beol)))
        /* must be after exponent or not in number because we start a number */
        + Bcomment   * (ischr(c, options.comment  ) && strlen(options.comment))
        /* comment starts if we are waiting for it */
        + Bseparator * ischr(c, options.separator);

      /* special case to handle files written by fortran routines */
      if (options.fortran && (c == '-' || c == '+') && (last_is & (Bnumber | Bpoint))) {
        last_is |= Bseparator;  /* [NUM|NUM.] [+|-] NUM -> 2 fortran numbers are touching each other */
        if (options.verbose && options_warnings-- > 0)
          print_stderr("Warning: File '%s' c='%c' [num pos=%li] two fortran numbers are touching each other\n",
          file.Source, c, startnumpos);
      }

      if (is & Bseparator) c=' ';
      if (!(is & Beol) && !(is & Bseparator) && c != EOF && !lk_isprint(c)) { c='b'; is |= Bseparator; }
      
      if (!(possiblecmt) && (is & Bcomment)) { /* activate new comment field */
        possiblecmt = 1;
      }
      if (possiblecmt) {  /* we are in a comment */
        if (is & Beol) {  /* end comment on eol */
          fieldend   |= Bcomment;
          possiblecmt = 0;
        } else is = last_is;  /* keeps last non-comment char state */
      } /* if (possiblecmt) */
      
      /* detect a start of numeric, or NaN or Inf */
      if ( (!possiblecmt) && (!possiblenum) && ((is & needforstartnum) || c == 'n' || c == 'i')
        && (last_is & (Bseparator | Beol))) { /* activate num search after separator */
        possiblenum = 1;
        startnumpos = pos;
        need        = needforstartnum;
        inpoint     = 0;
        inexp       = 0;
      } /* if ( (!possiblecmt) ... */

      if (possiblenum && !(possiblecmt)) { /* in num field */
        found = is & need;
        if (last_is & (Bseparator | Beol)) {
          if      (c == 'n') { isNAN=1; }
          else if (c == 'i') { isINF=1; }
        }
          
        /* handle NaN and Inf scanning */
        if (isNAN && isNAN <= strlen(sNAN) && c == sNAN[isNAN -1]) {
          found = 1;
          is |= Bnumber; 
          isNAN++;
        }
        else isNAN=0;
        if (isINF && isINF <= strlen(sINF) && c == sINF[isINF -1]) {
          found = 1;
          is |= Bnumber; 
          isINF++;
        }
        else isINF=0;

/* last column : update when found and (EOL and not groupnum)
*                or (EOL and groupnum and columns (not empty previous num line))
* OK : columns = 0 when EOL
* OK : newline : when found after EOL (can be really before -> if columns == 1)
* end of num field : found && columns != last_columns
*/
        if ((last_is & (Bnumber | Bpoint)) && (is & (Beol | Bseparator))) {
          columns++; /* detects num end : one more column */
          if (found && (columns <= 1)) rows++;  /* this is a new line starting */
        }
        if (is & Beol) {  /* reached end of line */
          if (!options.catenate) {
            if ((columns != last_columns) && (startnumpos < last_eolpos)) {
              /* change in columns -> end of preceeding num field */
              endnumpos = last_eolpos > 0 ? last_eolpos - 1 : 0;
              pos       = last_eolpos;
              is        = Beol;
              need      = needforstartnum;
              fieldend |= Bnumber;
              endcharpos= startnumpos > 0 ? startnumpos - 1 : 0;
              columns   = last_columns;
              rows--; /* remove row with less/more columns than the previous */
              if (startcharpos <= endcharpos) fieldend |= Balpha;
            } else {  /* still in numeric field with same num of columns: NewLine */
              last_columns = columns;
              columns = 0;
            }
          } else { /* when (catenate) */
            if (columns || !last_columns) {
              if (columns && !last_columns) {
                last_columns = columns;  /* first line on matrix */
                columns = 0;
              } else {
                if (last_columns && (columns != last_columns)  && (startnumpos < last_eolpos)) {
                  /* change in columns -> end of preceeding num field */
                  if (found) rows--;
                  endnumpos = last_eolpos > 0 ? last_eolpos - 1 : 0;
                  pos       = last_eolpos;
                  is        = Beol;
                  need      = needforstartnum;
                  fieldend |= Bnumber;
                  endcharpos= startnumpos > 0 ? startnumpos - 1 : 0;
                  columns   = last_columns;
                  if (startcharpos <= endcharpos) fieldend |= Balpha;
                }
                else columns = 0;
              } /* else */
            } /* if (columns ... else pass on : continue in same field */
          } /* if (!catenate) */
        } /* if (is & Beol) */

        if (!found) {
          isNAN       = isINF=0;
          if (last_is & (Beol | Bseparator) && (need != Bnumber)) {
            /* end of num field ok, except when the num started by a
               single point, not follwed by a 0-9 number */
            endnumpos  = pos - 2;
            endcharpos = startnumpos > 0 ? startnumpos - 1 : 0;
            fieldend  |= Bnumber;
            if (last_columns == 0)       last_columns = columns;
            if (startcharpos <= endcharpos) fieldend |= Balpha;
          } else { /* anomalous end of num */
            if (startnumpos >= last_seppos) {
              /* first possible number is not a number */
              columns     = last_columns;
              possiblenum = 0; /* abort and pass */
              if (fieldend & Bnumber) fieldend -= Bnumber;
            } else {
              if ((columns > 0) && (startnumpos >= last_eolpos)) { /* only a line */
                endnumpos = last_seppos > 0 ? last_seppos - 1 : 0;
                pos       = last_seppos;
                is        = Bseparator;
                need      = needforstartnum;
                fieldend |= Bnumber;
                endcharpos = startnumpos > 0 ? startnumpos - 1 : 0;
                if (fseek(file.SourceHandle, pos, SEEK_SET) && options_warnings-- > 0) {/* reposition after SEP */
                  print_stderr(
                  "Error: Repositiong error at position %ld in file '%s'\n"
                  "       Ignoring (may generate wrong results) [looktxt:file_scan:sep:%d]\n", pos, file.Source,__LINE__);
                  perror("");
                }
                if (startcharpos <= endcharpos) fieldend |= Balpha;
              } else { /* already passed more than one line */
                endnumpos = last_eolpos > 0 ? last_eolpos - 1 : 0;
                pos       = last_eolpos;
                is        = Beol;
                need      = needforstartnum;
                fieldend |= Bnumber;
                endcharpos= startnumpos > 0 ? startnumpos - 1 : 0;
                columns   = last_columns;
                if (fseek(file.SourceHandle, pos, SEEK_SET) && options_warnings-- > 0) { /* reposition after EOL */
                  print_stderr(
                  "Error: Repositiong error at position %ld in file '%s'\n"
                  "       Ignoring (may generate wrong results) [looktxt:file_scan:eol:%d]\n", pos, file.Source,__LINE__);
                  perror("");
                }
                if (startcharpos <= endcharpos) fieldend |= Balpha;
              } /* else */
            } /* else from if (startnumpos ... */
          } /* else from if (last_is ... */
        } else { /* found: still in num */
          if (is & Bpoint) {
            if (inpoint || inexp) need = 0;
            else {
              if (last_is & (Bseparator | Beol)) need = Bnumber;
              else need = needafterpoint;
              inpoint = 1;
            } /* else from if (inpoint ... */
          } else if (is & Bsign)      need = needaftersign;
          else if (is & Bexp)       { need = needafterexp; inpoint = 0; inexp = 1; }
          else if (is & Bseparator) { need = needaftersep; inpoint = 0; inexp = 0; }
          else if (is & Bnumber)      need = needafternumber;
          else if (is & Beol)       { need = needaftereol; inpoint = 0; inexp = 0; }
          else need = needafternumber;
        } /* else from if (!found) */
      } /* if (possiblenum ... */

      /* fill in table when a field has been found */
      if (fieldend) {
        struct data_struct field;

        field         = data_init();
        field.index   = fieldindex;
        /* define char header associated field */
        if (fieldend & Balpha) {
          field.c_start = startcharpos;
          field.c_end   = endcharpos > startcharpos ? endcharpos : startcharpos;

          /* startcharpos  = pos; */
          fieldend     -= Balpha;
        } /* Balpha */
        /* define numeric field */
        if (fieldend & Bnumber) {
          
          if (rows>1 && columns != last_columns && columns && last_columns) {
            /* case when a vector is split on many lines (fortran style) */
            rows=1; columns += rows*last_columns;
          } else {
            /* keep a matrix shape. Should reposition after previous eol */
            columns = last_columns;
          }
          if (columns && (startnumpos <= endnumpos))
          {
            if (rows <= 0) rows = 1;
            
            field.n_start = startnumpos;
            field.n_end   = endnumpos > startnumpos ? endnumpos : startnumpos;
            field.rows    = rows;
            field.columns = columns;

            table_add(table, field);  /* STORING field, Name=Section=NULL */
            
            pos      = endnumpos+1;
            startcharpos = pos;
            if (fseek(file.SourceHandle, pos, SEEK_SET) && options_warnings-- > 0) { /* reposition after Numeric */
              print_stderr(
              "Error: Repositiong error at position %ld in file '%s'\n"
              "       Ignoring (may generate wrong results) [looktxt:file_scan:Bnumber:%d]\n", pos, file.Source,__LINE__);
              perror("");
            }
            fieldindex++;
          } /* if (columns ... */
          possiblenum  = 0;
          last_eolpos  = endnumpos;
          /* startcharpos = endnumpos+1; */
          fieldend    -= Bnumber;
          columns      = 0;
          rows         = 0;
          last_columns = 0;
          inpoint      = 0;
        } /* Bnumber */
        /* ignore comment blocks */
        if (fieldend & Bcomment) {
          possiblecmt  = 0;
          fieldend    -= Bcomment;
          /* startcharpos = pos+1; */
        } /* Bcomment */

      } /* if (fieldend) */

      if ((is & Beol)) {
        last_eolpos = pos;
        last_seppos = pos;
      }

      if (is & Bseparator) { last_seppos = pos; }
      pos++;

    } while (c != EOF); /* end do */
    time(&EndTime);
    if (options.verbose >= 2)
      printf("VERBOSE[file_scan]: time elapsed %g [s]\n", difftime(EndTime,StartTime));
  } /* if (file.Source */
  return(table);
} /* file_scan */

/*****************************************************************************
* file_write_tag: Write output file Section Begin/End using selected format
*****************************************************************************/
int file_write_tag(struct file_struct file, struct option_struct options,
                       char *section, char *name, char *value, char *format)
{
  int   ret           =0;

  if (!format || !name || !value || !file.TxtHandle) return(0);

#ifdef USE_MAT
  if (options.ismatnexus == 1 || options.ismatnexus == 3) {  /* MAT/MEX output */
    mxArray *mxString=NULL;
    if (options.verbose > 2) 
      printf("DEBUG[file_write_tag]: writing in MAT/MEX: %s.%s=%s\n", 
        section && strlen(section) ? section : "ROOT", name, value);
    /* assign the name/value to structure, possibly as a sub-structure */
    if (!file.mxRoot || !mxIsStruct(file.mxRoot)) return(0);
    
    mxString = mxCreateString(value);

    if (section && strlen(section)) {
      
      char parent=0;
      char section_created = 0;
      mxArray *mxSection=NULL;
      mxArray *Parent=NULL;

      /* determine if the section exists in Data or Headers. 
         Create structure if needed */
      /* when out_headers == 2 we send the field to Headers */
      if (options.out_headers != 2)
        Parent = file.mxData;
      else
        Parent = file.mxHeaders;

      mxSection = mxGetField(Parent, 0, section);
      if (!mxSection || !mxIsStruct(mxSection)) { 
        /* need to create the field in the Data/Header ? */
        mxAddField(Parent, section);
        mxSection = mxCreateStructMatrix(1,1, 1, (const char **)&name);
        section_created = 1;
        if (!mxSection || !mxIsStruct(mxSection)) 
          exit(print_stderr("mxSection %s.%s.%s is empty\n",
            options.out_headers == 2 ? "Headers" : "Data", section, name));
      } else mxAddField(mxSection,    name);
      
      mxSetField(mxSection, 0, name,    mxString);
      mxSetField(Parent,    0, section, mxSection);

      if (options.out_headers != 2)
        file.mxData    = Parent;
      else
        file.mxHeaders = Parent;
    } else {
      if (options.out_headers == 2) {
        mxAddField(file.mxHeaders,       name);
        mxSetField(file.mxHeaders,    0, name,    mxString);
      } else {
        mxAddField(file.mxRoot,       name);
        mxSetField(file.mxRoot,    0, name,    mxString);
      }
    }
#ifndef USE_MEX
    mxDestroyArray(mxString);
#endif /* do not free in MeX mode */
    mxString = NULL;
  } else 
#endif /* USE_MAT */
#ifdef USE_NEXUS
  if (options.ismatnexus == 2) {  /* HDF/NeXus output */
    int length = strlen(value);
    NXMDisableErrorReporting(); /* unactivate NeXus error messages */
    NXmakedata(file.nxHandle, name, NX_CHAR, 1, &length);
    NXopendata(file.nxHandle, name);
    ret = NXputdata (file.nxHandle, value);
    if (ret == NX_ERROR) ret=0; else ret=1;
    NXclosedata(file.nxHandle);

    NXMEnableErrorReporting();  /* enable NeXus error messages */
  } else
#endif /* USE_NEXUS */
  if (!options.ismatnexus) {
    char  str_struct[]  =".";
    char *struct_section=NULL;
    char *struct_name   =NULL;
  
    if (options.use_struct) str_struct[0] = options.use_struct;
    if (section && strlen(section)) {
      if (options.use_struct && file.RootName && strlen(file.RootName) && !strstr(options.format.Name,"IDL"))
        struct_section = str_cat(str_struct, section, NULL);
      else {
        if (strstr(options.format.Name,"YAML"))
          struct_section = str_cat("  ", NULL);
        else struct_section = str_dup(section);
      }
    } else struct_section = str_dup(strstr(options.format.Name,"IDL") ? ROOT_SECTION : "");
    if (name && strlen(name)) {
      if (options.use_struct) struct_name = str_cat(str_struct, name, NULL);
      else struct_name = str_dup(name);
    } else struct_name = str_dup("");

    if (strstr(options.format.Name,"IDL") || strstr(options.format.Name,"Scilab")
     || strstr(options.format.Name,"Matlab") || strstr(options.format.Name,"Octave"))
     str_rep(value, "'","\"");
   
    ret = pfprintf(file.TxtHandle, format, "ssss",
      file.RootName ? file.RootName : "", /* 1  BAS=PAR=ROT  */
      struct_section,/* 2  SEC  */
      struct_name,   /* 3  NAM  */
      value);        /* 4  VAL  */

    struct_section=str_free(struct_section); struct_name=str_free(struct_name);
  }

  return(ret);

} /* file_write_tag */

/*****************************************************************************
* file_write_headfoot: Write output file Header and Footer using selected format
* Used by: file_write_target
*****************************************************************************/
int file_write_headfoot(struct file_struct file, struct option_struct options, char *format)
{
  char  *user=NULL;
  char   date[64];
  long   date_l; /* date as a long number */
  int    ret=1;
  time_t t;

  if (!file.TargetTxt || !format || !strlen(format) || !file.TxtHandle) return(0);

  if (options.verbose >= 3)
    printf("\nDEBUG[file_write_headfoot]: Writing %s header/footer\n", file.TargetTxt);
  time(&t);
  date_l = (long)t;
  t = (time_t)date_l;

  user = str_cat(
    getenv("USER") ? getenv("USER") : "looktxt",
    " on ",
    getenv("HOST") ? getenv("HOST") : "localhost", NULL);

  strncpy(date, ctime(&t), 64);
  if (strlen(date)) date[strlen(date)-1] = '\0';

#ifdef USE_NEXUS
  if (options.ismatnexus == 2) 
  { 
    if (format == options.format.Header) {
      /* add NeXus file attributes to 'root' level  */
      char tmp[1024];
      sprintf(tmp, "looktxt " VERSION " " DATE " " AUTHOR 
        "\nCopyright (C) 2009 Institut Laue Langevin <http://www.ill.eu/computing>"
        "\nPart of <ifit.mccode.org> (C) ILL");
      NXputattr(file.nxHandle, "creator", 
        tmp, strlen(tmp), NX_CHAR);
      NXputattr(file.nxHandle, "user", 
        user, strlen(user), NX_CHAR);
      NXputattr(file.nxHandle, "format", 
        options.format.Name, strlen(options.format.Name), NX_CHAR);
      NXputattr(file.nxHandle, "command", 
        options.option_list, strlen(options.option_list), NX_CHAR);
      /* then navigate to root 'entry' */
      NXopengroup(file.nxHandle,
        options.names_root && strcmp(options.names_root,"NULL") ? options.names_root : "entry", 
        "NXentry");
      /* stay here for the header tags below */
    }
  }  
  else
#endif /* USE_NEXUS */
  if (!options.ismatnexus)
  ret = pfprintf(file.TxtHandle, format, "sssslsssssl",
    options.format.Name,                  /* 1   FMT */
    user,                                 /* 2   USR */
    options.option_list,                  /* 3   CMD */
    file.Source,                          /* 4   SRC=TIT=FIL */
    file.Size,                            /* 5   SIZ */
    ctime(&file.Time),                    /* 6   TIM */
    file.TargetTxt,                       /* 7   TXT */
    file.TargetBin ? file.TargetBin : "", /* 8   BIN */
    file.RootName ? file.RootName : "",   /* 9   BAS=PAR=NAM=ROT */
    date,                                 /* 10  DATE */
    date_l);                              /* 11  DATL */
    
  if (format == options.format.Header) {
    char tmp[256];
    char tmp2[1024];
    strcpy(tmp, "Creator");
    sprintf(tmp2, "looktxt " VERSION " " DATE " " AUTHOR 
        "; Copyright (C) 2009 Institut Laue Langevin <http://www.ill.eu/computing>"
        "; Part of <ifit.mccode.org> (C) ILL");
    file_write_tag(file, options, "", str_lowup(tmp, options.names_lowup),
      tmp2,
      options.format.AssignTag);
    strcpy(tmp, "User");
    file_write_tag(file, options, "", str_lowup(tmp, options.names_lowup),
      user,
      options.format.AssignTag);
    strcpy(tmp, "Source");
    file_write_tag(file, options, "", str_lowup(tmp, options.names_lowup),
      file.Source,
      options.format.AssignTag);
    strcpy(tmp, "Date");
    file_write_tag(file, options, "", str_lowup(tmp, options.names_lowup),
      date,
      options.format.AssignTag);
    strcpy(tmp, "Format");
    file_write_tag(file, options, "", str_lowup(tmp, options.names_lowup),
      options.format.Name,
      options.format.AssignTag);
    strcpy(tmp, "Command");
    file_write_tag(file, options, "", str_lowup(tmp, options.names_lowup),
      options.option_list,
      options.format.AssignTag);
    strcpy(tmp, "Filename");
    file_write_tag(file, options, "", str_lowup(tmp, options.names_lowup),
      file.TargetTxt,
      options.format.AssignTag);
    strcpy(tmp, "Variable");
    file_write_tag(file, options, "", str_lowup(tmp, options.names_lowup),
      file.RootName ? file.RootName : "",
      options.format.AssignTag);
#ifdef USE_NEXUS
    if (options.ismatnexus == 2 && format == options.format.Header) {
      /* we assume entry.Data is now the storage location. Access to Headers will be 
        achieved specifically */
      NXopengroup(file.nxHandle, "Data", "NXentry"); 
    }
#endif
  }
  /* no flush when in MAT/NeXus/HDF format */
  if (!options.ismatnexus) fflush(file.TxtHandle);
#ifdef USE_NEXUS
  else if (options.ismatnexus == 2) {
    NXflush(&(file.nxHandle));
  }
#endif
  user=str_free(user);
  return(ret);

} /* file_write_headfoot */

/*****************************************************************************
* file_write_section: Write output file Section Begin/End using selected format
* Used by: file_write_section
*****************************************************************************/
int file_write_section(struct file_struct file, struct option_struct options,
                       char *section, char *format)
{
  int   ret=1;

  /* ROOT section should be ignored */
  if (!format          || !section || !strlen(section) || !file.TxtHandle
   || (!strstr(options.format.Name,"IDL") && !strcmp(section, ROOT_SECTION))) return(0);

  if (options.verbose >= 2)
    printf("VERBOSE[file_write_section]: file '%s': Writing %s begin/end section\n", file.TargetTxt, section);

  if (!options.ismatnexus) {
    char str_struct[]=".";
    char *struct_section=NULL;
  
    if (options.use_struct) str_struct[0] = options.use_struct;
    if (section && strlen(section)) {
      if (options.use_struct && file.RootName && strlen(file.RootName) && !strstr(options.format.Name,"IDL"))
        struct_section = str_cat(str_struct, section, NULL);
      else struct_section = str_dup(section);
    } else struct_section = str_dup(strstr(options.format.Name,"IDL") ? ROOT_SECTION : "");
    
    pfprintf(file.TxtHandle, format, "sss",
      file.RootName ? file.RootName : "",     /* 1  BAS=PAR  */
      struct_section,                         /* 2  SEC  */
      section ? section : "");                /* 3  NAM=TIT */
    struct_section=str_free(struct_section);
  }
#ifdef USE_NEXUS
  else if (options.ismatnexus == 2) {
    NXMDisableErrorReporting(); /* unactivate NeXus error messages */
    if (format == options.format.BeginSection) {
      NXmakegroup(file.nxHandle, section, "NXdata");
      NXopengroup(file.nxHandle, section, "NXdata");
    } else
      NXclosegroup(file.nxHandle);

    NXMEnableErrorReporting();  /* enable NeXus error messages */
  }
#endif

  return (ret);

} /* file_write_section */

/*****************************************************************************
* file_write_field_data: Write output file Data Begin/End strings using selected format
*     Actual Data array is written by file_write_field_array
* Used by: file_write_target
*****************************************************************************/
int file_write_field_data(struct file_struct file,
                          struct option_struct options,
                          struct data_struct field, char *format)
{
  char str_struct[]=".";
  char *struct_section=NULL;
  char *struct_name=NULL;
  char *name    =field.Name_valid;
  char *section =field.Section;

  if (!format || !field.Name || !strlen(field.Name) || !file.TxtHandle) return(0);
  if (!field.rows) return(0);
  if (options.verbose >= 3) {
    printf("\nDEBUG[file_write_field_data]: file '%s': Writing Part Data %s begin/end\n", file.TargetTxt, field.Name);
  }

  if (options.use_struct) str_struct[0] = options.use_struct;

  if (section && strlen(section)) {
    if (options.use_struct && file.RootName && strlen(file.RootName) && !strstr(options.format.Name,"IDL"))
      struct_section = str_cat(str_struct, section, NULL);
    else {
      if (strstr(options.format.Name,"YAML"))
        struct_section = str_cat("  ", NULL);
      else struct_section = str_dup(section);
    }
  } else struct_section = str_dup(strstr(options.format.Name,"IDL") ? ROOT_SECTION : "");

  if (name && strlen(name)) {
    if (options.use_struct && !strstr(options.format.Name,"IDL")) struct_name = str_cat(str_struct, name, NULL);
    else struct_name = str_dup(name);
  } else struct_name = str_dup("Name");

/* default BAS.Data.Section.Name */
  if (!options.ismatnexus) pfprintf(file.TxtHandle, format, "ssslls",
    struct_section,  /* 1 SEC */
    field.Name,      /* 2 TIT */
    struct_name,     /* 3 NAM */
    field.rows,      /* 4 ROW */
    field.columns,   /* 5 COL */
    file.RootName ? file.RootName : "");    /* 6 BAS  */

  struct_name=str_free(struct_name); struct_section=str_free(struct_section);

  return(1);

} /* file_write_field_data */

#if defined(USE_MAT) || defined(USE_NEXUS)
/*****************************************************************************
* file_write_field_array_matnexus: Write output file Data array using Mat/NeXus format
* Used by: file_write_target, file_write_field_array
*****************************************************************************/
int file_write_field_array_matnexus(struct file_struct file,
                          struct option_struct options,
                          struct data_struct field, struct strlist_struct to_catenate)
{
  long   index_field=0;
  double *data      =NULL;
  long   num_rows   =0; /* total number of rows in array */
  long   num_index  =0; /* current number of rows in array (block by block) */
  int    ret        =0;
  
  num_rows = field.rows;
  /* compute the total size of the data (nb of rows, same nb of columns) */
  for (index_field=0; index_field < to_catenate.length; index_field++) {
    /* write catenated field data: rows x columns (but do not write bin reference yet) */
    struct  data_struct *f=(struct data_struct *)(to_catenate.List[index_field]);
    num_rows += f->rows;
  }
  
  /* get the first data block */
  data      = data_get_double(file, field, options); /* first block */
  if (field.rows < num_rows) { /* reallocate to the total size (rest is assigned below) */
    data = (double *)realloc(data, num_rows*field.columns*sizeof(double));
    if(data == NULL) {
      print_stderr( "Error: Memory exhausted during re-allocation of size %ld for '%s' [looktxt:file_write_field_array_matnexus:%d].", 
        num_rows*field.columns*sizeof(double), field.Name,__LINE__);
      exit(EXIT_FAILURE);
    }
  }
  num_index = field.rows*field.columns; /* number of elements already stored in 'data' */
  
  /* and append the other 'to catenate' blocks */
  for (index_field=0; index_field < to_catenate.length; index_field++) {
    double              *d    =NULL;
    struct  data_struct *f    =(struct  data_struct *)(to_catenate.List[index_field]);
    
    d = data_get_double(file, *f, options); /* consecutive block */
    if (!d) {
      print_stderr( "Error: Memory exhausted during re-allocation of size %ld for '%s' [looktxt:file_write_field_array_matnexus:%d].", 
        f->rows*f->columns*sizeof(double), f->Name,__LINE__);
      exit(EXIT_FAILURE);
    }

    /* catenate data (copy in 'data') */
    memcpy(&(data[num_index]), d, f->rows*f->columns*sizeof(double));
    num_index += f->rows*f->columns;      /* shift to next block index */
    f->rows=0;                            /* unactivate once treated */
    
    d=(double*)memfree(d);
  }
  
  if (options.verbose >= 3)
    printf("\nDEBUG[file_write_field_array_matnexus]: file '%s': Writing Data '%s' values (%ld x %ld) \n", 
      file.TargetTxt, field.Name, num_rows, field.columns);

#ifdef USE_MAT
  if (options.ismatnexus == 1 || options.ismatnexus == 3) { /* MAT file */
    /* Matlab uses a columns-wise storage convention (Fortran like) -> transpose */
    int      i,j;
    double  *tdata   = malloc(num_rows*field.columns*sizeof(double));
    mxArray *mxMatrix= NULL;
    
    for (i=0; i<num_rows; i++)
      for (j=0; j<field.columns; j++)
        tdata[j*num_rows+i] = data[i*field.columns+j];
    data = (double*)memfree(data); data=tdata; tdata=NULL;
    
    /* assign the name/value to structure, possibly as a sub-structure */
    if (!file.mxRoot || !mxIsStruct(file.mxRoot)) return(0);
    mxMatrix   =mxCreateNumericMatrix(
        num_rows, field.columns, mxDOUBLE_CLASS, mxREAL);
    memcpy((void *)(mxGetPr(mxMatrix)), (void *)data, num_rows*field.columns*sizeof(double));
    
    /* add field to 'Root'.'Data' */
    if (field.Section && strlen(field.Section)) {
      mxArray   *mxSection=mxGetField(file.mxData, 0, field.Section);
      char       section_created=0;
      if (!mxSection || !mxIsStruct(mxSection)) { 
        /* need to create the field in the Data/Header ? */
        mxAddField(file.mxData, field.Section);
        mxSection = mxCreateStructMatrix(1,1, 1, (const char **)&(field.Name_valid));
        section_created = 1;
        if (!mxSection || !mxIsStruct(mxSection)) {
          print_stderr("mxSection %s.%s.%s is empty\n",
            "Data", field.Section, field.Name_valid);
        } else ret=1;
      } else { mxAddField(mxSection, field.Name_valid); ret=1; }
      
      mxSetField(mxSection,   0, field.Name_valid,  mxMatrix);
      mxSetField(file.mxData, 0, field.Section,     mxSection);
      
    } else {
      mxAddField(file.mxData,       field.Name_valid);
      mxSetField(file.mxData,    0, field.Name_valid,    mxMatrix);
      ret=1;
    }
#ifndef USE_MEX
    mxDestroyArray(mxMatrix);
#endif /* do not free in MeX mode */
    mxMatrix = NULL;
  }
#endif
#ifdef USE_NEXUS
  if (options.ismatnexus == 2) { /* NeXus/HDF file */
    int length[2]={num_rows,field.columns};
    
    NXMDisableErrorReporting(); /* unactivate NeXus error messages */
    NXsetcache(1024000*10);
    /* create the Data block. NXcompmakedata is buggy, uses all memory */
    NXmakedata(file.nxHandle, field.Name, NX_FLOAT64, 2, length);
    NXopendata(file.nxHandle, field.Name);
    ret = NXputdata (file.nxHandle, data);
    if (ret == NX_ERROR) ret=0; else ret=1;
    NXclosedata(file.nxHandle);
    NXMEnableErrorReporting();  /* enable NeXus error messages */
  }
#endif
  /* free the numerical double array */
  data = (double*)memfree(data);
  
  return(ret);
  
} /* file_write_field_array_matnexus */
#endif /* defined(USE_MAT) || defined(USE_NEXUS) */

/*****************************************************************************
* file_write_field_array: Write output file Data array using selected format
* Used by: file_write_target
*****************************************************************************/
int file_write_field_array(struct file_struct file,
                          struct option_struct options,
                          struct data_struct field, char *format)
{
  char    flag_written=0;
  double *data   =NULL;
  long    count  =0;
  long    length =0;
  
  /* handle text for nelements <= MAX_TXT4BIN */
  /*        binary for big */
  data = data_get_double(file, field, options);
  if (!data) {
    if (options.verbose >= 1  && options_warnings-- > 0)
    if (options.verbose >= 2 || field.n_start < field.n_end)
    print_stderr("Warning: File '%s': Data %s is empty (%ld:%ld)\n",
      file.TargetTxt, field.Name, field.n_start, field.n_end);
    return(0);
  }
#if defined(USE_MAT) || defined(USE_NEXUS)
  if (options.ismatnexus)
  { /* write data block in MAT file */ 
    struct  strlist_struct to_catenate = strlist_init("empty");
    count = file_write_field_array_matnexus(file,options, field, to_catenate);
    strlist_free(to_catenate);
    return(count);
  }
  else
#endif /* defined(USE_MAT) || defined(USE_NEXUS) */
  if (((field.rows*field.columns > MAX_TXT4BIN && options.use_binary==1) || options.use_binary==2) && file.BinHandle) {
    /* write bin array in BinHandle */
    size_t start, end;
    start=ftell(file.BinHandle); /* file opened previously */
    /* position at end of Bin, store that pos */
    count = fwrite(data, sizeof(double),
      field.rows*field.columns, file.BinHandle);
    if (count != field.rows*field.columns && options_warnings-- > 0) {
       print_stderr( "Warning: Could not write properly field %s in BIN file '%s'.\n"
         "(permissions, disk full, broken link ?). Using TXT output [looktxt:file_write_field_array:%d]\n",
         field.Name, file.TargetBin,__LINE__);
    } else {
      if (options.verbose >= 3)
        printf("\nDEBUG[file_write_field_array]: file '%s': Writing Data '%s' values (%ld x %ld) \n", 
        file.TargetBin, field.Name, field.rows, field.columns);
      if (format) {
        /* get eof Bin, store pos */
        end = ftell(file.BinHandle); if (end > 1) end--;
        /* write reference (TargetBin, start,end, length) in TxtHandle */

        length=end-start+1;
        if (file.TxtHandle) pfprintf(file.TxtHandle, format, "slllll",
          file.TargetBin, /* 1 FIL */
          start,          /* 2 BEG */
          end,            /* 3 END */
          length,         /* 4 LEN */
          field.rows,     /* 5 ROW */
          field.columns); /* 6 COL */
      }
      flag_written=1;
    }
  }
  if (!flag_written) {
    int i,j;
    double value;
    /* write in TxtHandle */
    if (options.verbose >= 3)
      printf("\nDEBUG[file_write_field_array]: file '%s': Writing Data %s values (%ld x %ld) \n", 
        file.TargetTxt, field.Name, field.rows, field.columns);
    for (i=0; i<field.rows; i++) {
      if (file.TxtHandle && strstr(options.format.Name,"YAML"))
        fprintf(file.TxtHandle, "%s-  [", field.Section && strlen(field.Section) ? "  " : "");
      for (j=0; j<field.columns; j++) {
        int this_count=0;
        value = data[i*field.columns+j];
        this_count = file.TxtHandle ? 
          fprintf(file.TxtHandle, "%g%c", value,
            (strstr(options.format.Name,"IDL") || strstr(options.format.Name,"YAML")) && i*field.columns+j < field.columns*field.rows-1 ? ',' : ' ') : 1;
        if (!this_count && options_warnings-- > 0) {
          print_stderr( "Warning: Could not write properly field %s in TXT file '%s'.\n"
            "(permissions, disk full, broken link ?) [looktxt:file_write_field_array:%d]\n",
            field.Name, file.TargetBin,__LINE__);
          count = 0;
          break;
        } else count += this_count;
      }
      if (!count) break;
      else if (file.TxtHandle) {
        if (strstr(options.format.Name,"IDL"))
          fprintf(file.TxtHandle, "$\n" );
        else {
          if (strstr(options.format.Name,"YAML"))
            fprintf(file.TxtHandle, "]\n");
          else
            fprintf(file.TxtHandle, "\n");
        }
      }
    }
  }
  data = (double*)memfree(data);
  return (count > 0);
} /* file_write_field_array */






/* definition of a write structure, which gathers section information ******* */

struct write_struct {
  struct strlist_struct section_names;  /* name of found sections */
  struct strlist_struct section_fields; /* fields registered for each found section (in the same order as section_names */
};

/*****************************************************************************
* file_write_getsections: Prepare output file using selected format
*     handle metadata, fortran style, makerow, set field name
*     returns found sections structure
* Used by: parse_files
*****************************************************************************/
struct write_struct file_write_getsections(struct file_struct file,
                       struct option_struct options,
                       struct table_struct *ptable)
{
  long    index;  /* index of current field from table */
  long    length;
  char   *section_current=NULL;  /* current section full name */
  char   *last_valid_name=NULL;
    
  struct strlist_struct section_names;  /* name of found sections */
  struct strlist_struct section_fields; /* fields registered for each found section (in the same order as section_names */
  struct write_struct found_sections;
  
  struct table_struct *metatable;  /* table for metadata */
  section_current = str_cat("MetaData_",file.RootName, NULL);
  metatable       = table_init(section_current);
  section_current = str_free(section_current);

  /* create section field names arrays */
  section_current= str_dup(ROOT_SECTION);  /* Init default section (root) */

  section_names  = strlist_init("section_names");
  section_fields = strlist_init("section_fields");
  strlist_add(&section_names,  section_current); /* ROOT is 0. Already set in parse ags */
  strlist_add(&section_fields, " "); /* no filed stored yet */

  if (options.verbose >= 2)
      printf("VERBOSE[file_write_getsections]:  Analyze header [0-%ld], sections [%li] and metadata [%li] ...\n", ptable->length-1,options.sections.length,options.metadata.length);

  length = ptable->length;

  /* FIRST PASS: read header, search sections and set raw name for all fields */
  for (index=0; index < length; index++)
  {
    struct  data_struct *field;  /* current field from file */
    long    index_meta, index_sec;
    char   *header=NULL;
    field  = &(ptable->List[index]);
    if (field->c_start > field->c_end) continue;
    header = data_get_char(file, field->c_start, field->c_end);
    for (index_meta=0; index_meta < options.metadata.length; index_meta++)
    { /* scan all MetaData registered entries */
      char *this_metadata=NULL;
      long  section_index=-1;

      section_index = strlist_search(section_names, "MetaData");
      this_metadata = options.metadata.List[index_meta];

      /* if metadata is found in the header */
      if (this_metadata && strlen(this_metadata) && header && strstr(header, this_metadata)) {
        long  offset=0;
        char *metadata_line=NULL;

        offset = field->c_start;

        do {
          struct data_struct data;
          metadata_line = data_get_line(file, &offset); /* get line and move forward in lines. Includes EOL */

          if (metadata_line && strlen(metadata_line) > 1 && strstr(metadata_line, this_metadata)) {
            /* add the MetaData section */
            if (section_index<0) {
                strlist_add(&section_names,  "MetaData");
                strlist_add(&section_fields, " ");
                section_index = strlist_search(section_names, "MetaData");
                if (section_index<0 && options.verbose >= 3)
                  printf("\nDEBUG[file_write_target]: Could not create MetaData list to register item %s\n", this_metadata);
            }
            str_valid_eol(metadata_line, options);

            /* that same field belongs to more than one MetaData: we duplicate it */
            data = data_init();
            data.Name   = str_dup(this_metadata);
            data.Header = str_dup(metadata_line);       /* line following the metadata */
            data.Section= str_dup("MetaData"); /* Section name */
            data.index  = index;      /* index of this data block */
            data.rows   = field->rows;
            data.columns= field->columns;
            data.n_start= field->n_start;
            data.n_end  = field->n_end;
            data.c_start= field->c_start;
            data.c_end  = field->c_end;
            table_add(metatable, data); /* duplicated field */
          } /* if metadata_line */
        } while (offset < field->c_end);
      } /* if strstr header */
    } /* for index_meta */
      
    /* if output does not support \n in chars, make header valid */
    str_valid_eol(header, options);
    
    /* use default naming convention=last word in header */
    field->Name    = str_lastword(header); /* was NULL before */
    
    field->Header  = str_dup(header);
    header=str_free(header);

    if (field->Name && strlen(field->Name)) {
      last_valid_name=str_free(last_valid_name); last_valid_name = str_dup(field->Name);
    }

    /* fortran case: single row, no name */
    if (options.fortran && index > 0 && field->rows == 1 && (!field->Name || !strlen(field->Name))) {
      struct  data_struct *previous = &(ptable->List[index-1]);
      if (field->columns < previous->columns) {
      /* compute total length, and add it to previous */
        long columns=field->columns + previous->columns*previous->rows;
        previous->rows    = 1;            /* make it single row */
        previous->columns = columns;
        previous->n_end   = field->n_end; /* shift end of num */
        field->rows=0; /* unactivate */
        continue;
      }
    }
    if (options.makerows.length && last_valid_name && strlen(last_valid_name)) {
      for (index_sec=0; index_sec < options.makerows.length; index_sec++) {
        if (strstr(last_valid_name, options.makerows.List[index_sec])) {
          long columns=field->columns*field->rows;
          field->rows=1; field->columns=columns;
          str_free(field->Name);
          field->Name=str_dup(last_valid_name);
        }
      }
    }
    /* look for section names in header if any. skip ROOT */
    for (index_sec=0; index_sec < options.sections.length; index_sec++)
    { /* scan all registered sections */
      char *this_section=NULL;
      this_section = options.sections.List[index_sec];
      /* if a new section ID is found in the header */
      if (this_section && section_current && strcmp(section_current, this_section)) {
        /* this is not the present section */
        if (field->Header && strstr(field->Header, this_section)) {
          /* the header contains a new registered section ID */

          str_free(section_current);
          section_current = str_dup(this_section);

          if (field->Name && strstr(section_current, field->Name)) {
            /* if name is in the section str,
               then set section_name to <section_value> */
            char   value[256];
            double data0=0;      /* first numerical value */
            char  *tmp;
            if (fseek (file.SourceHandle, field->n_start-1 > 0 ? field->n_start-1 : 0, SEEK_SET) && options_warnings-- > 0)
              print_stderr( "Warning: Error in fseek(%s,%i) [looktxt:file_write_getsections:%d]\n",
                file.Source, field->n_start-1,__LINE__);
            if (!fscanf(file.SourceHandle, "%lf", &data0) && options_warnings-- > 0)
              print_stderr( "Warning: Error in reading double fscanf(%s) [looktxt:file_write_getsections:%d]\n",
                file.Source, __LINE__);
            sprintf(value, "_%ld", (long)data0);
            tmp = str_cat(section_current, value, NULL);
            str_free(section_current); section_current = tmp; tmp=NULL;
          }

          /* register: init the new section in the list of found sections in the file */
          if (strlist_search(section_names, section_current) < 0) {
            strlist_add(&section_names,  section_current);
            strlist_add(&section_fields, " ");
          }
        } /* if strstr(header ... */
      } /* if (strcmp(section_current, */
    } /* for (index_sec */

    /* set field section to current section */
    if (!field->Section)
      field->Section = str_dup(section_current); /* was NULL before except from MetaData */
      
  } /* for index 1st PASS */
  section_current=str_free(section_current);
  last_valid_name=str_free(last_valid_name);

  /* From here we have:
   * - a ptable->List of data_struct containing Name/Section fields,
   * - section_names Lists for each registered sections
   * - empty section_fields Lists corresponding to section_names
   */

  found_sections.section_names = section_names;
  found_sections.section_fields= section_fields;
  
  /* now catenate any metadata fields to the current ptable and free it */
  for (index=0; index < metatable->length; index++) {
    table_add(ptable, metatable->List[index]);
  }
  for (index=metatable->length; index<metatable->nalloc; data_free(metatable->List[index++]));
  metatable->Name=str_free(metatable->Name);
  metatable->length=metatable->nalloc=0;
  metatable->List=(struct data_struct *)memfree(metatable->List);
  free(metatable);

  return(found_sections);
} /* file_write_getsections */

/*****************************************************************************
* file_write_target: Write output file using selected format
*     returns the number of succesfully written fields
* Used by: parse_files
*****************************************************************************/
long file_write_target(struct file_struct file,
                       struct option_struct options,
                       struct table_struct *ptable,
                       struct strlist_struct section_names,
                       struct strlist_struct section_fields)
{
  int     index=0;  /* index of current field from table */
  char   *section_current      =NULL;  /* current section full name */
  char   *section_current_valid=NULL;  /* current section+struct full name */
  int     section_index=0;             /* start with root section */
  long    ret=0;                       /* return value=number of written fields */
  char   *last_valid_name=NULL;
  struct  strlist_struct to_catenate;
  long    redundant;
  
  time_t StartTime       =0;
  time_t EndTime         =0;

  if (!ptable || !ptable->length || !ptable->nalloc) return(0);
  
  time(&StartTime); /* compute starting time */
  
  if (options.verbose >= 2)
      printf("\nDEBUG[file_write_target]: Opening target file %s\n", file.TargetTxt);

  /* open output files txt/bin : failure -> file.TxtHandle=NULL*/
  if (!options.test) {
#ifdef USE_MAT
    if (options.ismatnexus == 1 || options.ismatnexus == 3) {
      /* Matlab MAT/MEX: we create the structure 'mx' */
      /* The 'root' structure for each Source file, will be populated with sections */
      /* Each section will be populated with fields */
      const char *data[] = {"Data"};
      file.mxRoot = mxCreateStructMatrix(1, 1, 1, data);  /* 'root' structure */
      if (options.out_headers)
        mxAddField(file.mxRoot, "Headers"); 
      if (!file.mxRoot || !mxIsStruct(file.mxRoot))
        exit(print_stderr("ERROR: mxRoot is not a structure [looktxt:file_write_target:%i]\n",__LINE__));
      
      /* now add all other Sections to 'Data' and 'Headers' */
      for (index=0; index < section_names.length; index++) {
        if (index == 0) {
          /* create the 'Data' and possibly 'Headers' sub-structures */
          file.mxData = mxCreateStructMatrix(1,1,1, (const char **)&(section_names.List[index]));
          if (options.out_headers)
            file.mxHeaders = mxCreateStructMatrix(1,1,1, (const char **)&(section_names.List[index]));
        }
        mxAddField(file.mxData, section_names.List[index]);
        if (options.out_headers)
          mxAddField(file.mxHeaders, section_names.List[index]);
      }
      file.TxtHandle = (FILE*)file.mxRoot;
    }
    else
#endif /* USE_MAT */
#ifdef USE_NEXUS
    if (options.ismatnexus == 2) {
      /* NeXus/HDF file */
      NXhandle pHandle;
      options.openmode[0] = 'w';
      NXopen(file.TargetTxt, 
        strstr(options.format.Name,"HDF4") ? NXACC_CREATE4 : NXACC_CREATE5, &pHandle);
      file.nxHandle  = pHandle;
      
      NXmakegroup(file.nxHandle, 
        options.names_root && strcmp(options.names_root,"NULL") ? options.names_root : "entry",
        "NXentry");
      NXopengroup(file.nxHandle,
        options.names_root && strcmp(options.names_root,"NULL") ? options.names_root : "entry", 
        "NXentry");
      /* create Data and possibly Headers groups */
      NXmakegroup(file.nxHandle, "Data", "NXentry");
      if (options.out_headers)
        NXmakegroup(file.nxHandle, "Headers", "NXentry");
      /* go back to root level */
      NXclosegroup(file.nxHandle); /* back to /, attributes will go there */
      file.TxtHandle = (FILE*)pHandle;
    } else
#endif /* USE_NEXUS */
    /* other text/binary files */
    if (file.TargetTxt) {
      if (!strcmp(file.TargetTxt, "stdout") || !strcmp(file.TargetTxt, "-"))
        file.TxtHandle=stdout;
      else if (!strcmp(file.TargetTxt, "stderr"))
        file.TxtHandle=stderr;
      else file.TxtHandle = fopen(file.TargetTxt, options.openmode);
    }
    if (file.TargetBin && options.use_binary) {
      if (!strcmp(file.TargetBin, "stdout") || !strcmp(file.TargetBin, "-"))
        file.BinHandle=stdout;
      else if (!strcmp(file.TargetBin, "stderr"))
        file.BinHandle=stderr;
      else file.BinHandle = fopen(file.TargetBin, options.openmode);
    }

    if (!file.TxtHandle) 
      exit(print_stderr( "Error: Can not open target file '%s' in mode %s. Exiting  [looktxt:file_write_target:%d]\n", 
        file.TargetTxt, options.openmode,__LINE__));
    if (!file.BinHandle && options.use_binary) {
      print_stderr( "Warning: Can not open binary target file '%s' in mode %s. Using text [looktxt:file_write_target:%d]\n", 
        file.TargetBin, options.openmode,__LINE__);
      options.use_binary = 0;
    }
  } /* if !options.text */

  section_current       = str_dup(ROOT_SECTION);
  section_current_valid = str_valid_struct(section_current, options.use_struct);

  if (options.verbose >= 2)
      printf("\nVERBOSE[file_write_target]: Write target file(s) [0-%ld]\n", ptable->length-1);

  /* SECOND PASS: read all table elements */

  /* write output header. begin root section+MetaData */
  file_write_headfoot(file, options, options.format.Header);

  if (strstr(options.format.Name, "IDL") && file.TxtHandle) {
    /* initiate section structures */
    for (index=0; index < section_names.length; index++) {
      if (options.out_headers) {
        fprintf(file.TxtHandle, "Headers%s = { Name:'Headers for Section %s' }\n",
          section_names.List[index], section_names.List[index]);
        fprintf(file.TxtHandle, "Data%s = { Name:'Data for Section %s' }\n",
          section_names.List[index], section_names.List[index]);
      } else
        fprintf(file.TxtHandle, "%s = { Name:'Section %s' }\n",
          section_names.List[index], section_names.List[index]);
    }
  }
  file_write_section(file, options, section_current, options.format.BeginSection);

  for (index=0; index < ptable->length; index++) {
    int     consecutive_index = 0;
    long    rows       =0;
    long    columns    =0;

    if (!ptable->List[index].rows) continue;
    
    rows   = ptable->List[index].rows;
    columns= ptable->List[index].columns;

    if (ptable->List[index].Name && strlen(ptable->List[index].Name)) {
      str_free(last_valid_name); last_valid_name = str_dup(ptable->List[index].Name);
    }

    /* get current field and search similar ones */
    to_catenate = strlist_init("fields_to_catenate");
    if (options.catenate) {
      for (consecutive_index=index+1; consecutive_index<ptable->length; consecutive_index++) {
        if (!ptable->List[consecutive_index].rows
          || ptable->List[consecutive_index].columns != columns) continue; /* must have same #columns */
        if (ptable->List[consecutive_index].Section && ptable->List[index].Section
         && strcmp(ptable->List[consecutive_index].Section, ptable->List[index].Section)) continue; /* same section */
        if (!ptable->List[consecutive_index].Name
        || (ptable->List[index].Name && !strcmp(ptable->List[consecutive_index].Name, ptable->List[index].Name))) {
          /* same name: add pointer to consecutive_index field */
          struct  data_struct *field=&(ptable->List[consecutive_index]);
          strlist_add_void(&to_catenate, (void*)field); /* trick to force storage of pointer */
        }
      }
    }

    /* from there we know the 'base' field and how many similar follow */

    /* detects section change, end previous, init new */
    if (!ptable->List[index].Section || strcmp(ptable->List[index].Section, section_current)) { /* field section is not current */
      file_write_section(file, options,
        section_current, options.format.EndSection);
      /* shift to field section from List */
      section_index = strlist_search(section_names, ptable->List[index].Section);
      if (section_index < 0 || section_index >= section_names.length)
        section_index=0; /* not found -> root */
      str_free(section_current);
      str_free(section_current_valid);
      section_current       = str_dup(section_names.List[section_index]);
      section_current_valid = str_valid_struct(section_current, options.use_struct);
      file_write_section(file, options, section_current,
        options.format.BeginSection);
    }

    /* setup the 'base' field name */
    if (!ptable->List[index].Name || !strlen(ptable->List[index].Name)) {  /* default name */
      char tmp[256];
      sprintf(tmp, "%s_%ld",
        last_valid_name ? last_valid_name : "Data", ptable->List[index].index);
      str_free(ptable->List[index].Name);
      ptable->List[index].Name = str_dup(tmp);
    } else {
      /* make field name valid */
      char *tmp;
      tmp = str_valid(ptable->List[index].Name, options.names_length);
      str_free(ptable->List[index].Name);
      ptable->List[index].Name = tmp;
    }

    /* make it lower/upper if option set */
    str_lowup(ptable->List[index].Name, options.names_lowup);
    str_lowup(ptable->List[index].Section, options.names_lowup);

    if (!ptable->List[index].Section || !strlen(ptable->List[index].Section)
      || (!strstr(options.format.Name,"IDL") && !strcmp(ptable->List[index].Section, ROOT_SECTION))) {
      str_free(ptable->List[index].Section);
      ptable->List[index].Section = str_dup("");
    }
    /* look if name matches one already registered in the section */
    /* we try with: name, name_(field.index), and name_(1-length) */
    redundant  = -1;
    do {
      char *name=NULL;
      char *to_register=NULL;
      char value[256];
      if (redundant < 0)     name = str_cat(ptable->List[index].Name, NULL);
      else if (redundant == 0) {
        sprintf(value,"_%ld", ptable->List[index].index);
        name = str_cat(ptable->List[index].Name, value, NULL);
      } else {
        sprintf(value,"_%ld", redundant);
        name = str_cat(ptable->List[index].Name, value, NULL);
      }

      to_register = str_cat(" ", name, " ", NULL);
      if (!section_fields.List[section_index] || !strstr(section_fields.List[section_index], to_register)) {
        /* exit loop: name not registered yet */
        char *new_section_fields=NULL;
        if (strlen(ptable->List[index].Name)<=options.names_length && strlen(name) > options.names_length) {
          long diff=strlen(name)-strlen(ptable->List[index].Name);
          char *name_shorter = str_dup_n(ptable->List[index].Name, strlen(ptable->List[index].Name)-diff);
          str_free(name);  name=str_cat(name_shorter, value, NULL);
          name_shorter=str_free(name_shorter);
        }
        str_free(ptable->List[index].Name); ptable->List[index].Name = name;
        new_section_fields= str_cat(section_fields.List[section_index], to_register, NULL);
        str_free(section_fields.List[section_index]);
        section_fields.List[section_index] = new_section_fields;
        str_free(to_register);
        break;
      } else {
        redundant++;
        name=str_free(name); to_register=str_free(to_register);
      }
    } while(redundant < ptable->length); /* exit with break */

    /* From there we have a base name, and we know if there are consecutive indices */

    if ((options.nelements_min <  0 || rows*columns >= options.nelements_min)
     && (options.nelements_max <= 0 || rows*columns <= options.nelements_max) 
     && ptable->List[index].rows 
     && (!options.metadata_only || (options.metadata_only && !strcmp(ptable->List[index].Section,"MetaData")))) {
      int index_field = 0;
      char *section=NULL;
      char str_struct[]=".";

      if (options.use_struct) str_struct[0] = options.use_struct;
      ptable->List[index].rows    = rows;
      ptable->List[index].columns = columns;
      ptable->List[index].Name_valid =
        str_valid(ptable->List[index].Name, options.names_length);
      /* Optional BAS.Headers.Section.Name */
      if (options.out_headers) {
#ifdef USE_NEXUS
        char nxPath[ALLOC_BLOCK];
#endif
        /* add Headers to Section for next header output */
        if (!options.ismatnexus) {
          section=str_cat("Headers",
            options.use_struct && ptable->List[index].Section && strlen(ptable->List[index].Section) ?
              str_struct : "",
            ptable->List[index].Section, NULL);
          str_lowup(section, options.names_lowup);
        } else
          section=str_dup(ptable->List[index].Section);

#ifdef USE_NEXUS
        if (options.ismatnexus == 2) {
          char *nxHeaderPath=str_cat("/",
            options.names_root && strcmp(options.names_root,"NULL") ? options.names_root : "entry",
            "/",
            "Headers", NULL);
          /* we are in entry.Data.<section> and move to entry.Headers.<section> */
          NXgetpath(file.nxHandle, nxPath, ALLOC_BLOCK);
          NXopenpath(file.nxHandle, nxHeaderPath);
          nxHeaderPath = str_free(nxHeaderPath);
          if (ptable->List[index].Section && strlen(ptable->List[index].Section)) {
            NXMDisableErrorReporting(); /* unactivate NeXus error messages */
            NXmakegroup(file.nxHandle, ptable->List[index].Section, "NXdata");
            NXopengroup(file.nxHandle, ptable->List[index].Section, "NXdata");
            NXMEnableErrorReporting();  /* enable NeXus error messages */
          }
          
        }
#endif
        options.out_headers = 2;
        file_write_tag(file, options, section,
                       ptable->List[index].Name_valid, ptable->List[index].Header,
                       options.format.AssignTag);
        options.out_headers = 1;
#ifdef USE_NEXUS
        if (options.ismatnexus == 2) {
          /* move back to entry.Data.<section> */
          NXopenpath(file.nxHandle, nxPath);
        }
#endif
        section=str_free(section); 

      }
      /* add "Data" to Section for next data output */
#if defined(USE_NEXUS) || defined(USE_MAT)
      if (options.ismatnexus)
        section = str_dup(ptable->List[index].Section);
      else
#endif
      section=str_cat("Data",
        options.use_struct && ptable->List[index].Section && strlen(ptable->List[index].Section) ?
          str_struct : "",
        ptable->List[index].Section, NULL);
      str_lowup(section, options.names_lowup);
      str_free(ptable->List[index].Section);
      ptable->List[index].Section = section;
      
      /* special case for IDL */
      if (strstr(options.format.Name,"IDL") && file.TxtHandle
          && (!ptable->List[index].rows || !ptable->List[index].columns
          || ptable->List[index].n_start >= ptable->List[index].n_end))
          fprintf(file.TxtHandle, "; %s %s is empty\n",
            ptable->List[index].Section, ptable->List[index].Name);
#if defined(USE_MAT) || defined(USE_NEXUS)
      else if (file.TxtHandle && options.ismatnexus) {
        /* treat specifically Mat and NeXus output for catenated data */
        /* need to build the full array before writing it */
        ret += file_write_field_array_matnexus(file, options, ptable->List[index], to_catenate);
      } else
#endif /* defined(USE_MAT) || defined(USE_NEXUS) */
     if (file.TxtHandle) {
        /* init base field: rows x columns as BAS.Data.Section.Name */
        file_write_field_data(file, options, ptable->List[index], options.format.BeginData);
        /* special case for IDL */
        if (strstr(options.format.Name,"IDL") && file.TxtHandle) fprintf(file.TxtHandle, "[ ");

        /* writing base field */
        if (!options.catenate || !to_catenate.length) /* text output */
          ret += file_write_field_array(file, options, ptable->List[index],
              options.format.BinReference);
        else { /* write catenated fields (same # columns) */
          long start, end, length;
          struct data_struct bin_field = ptable->List[index];

          start=options.use_binary && file.BinHandle ? 
                  ftell(file.BinHandle) : 0; /* file opened previously in binary mode */
          
          /* force binary blocks to be written whatever be their size */
          if (options.use_binary) options.use_binary=2; 

          /* write first block of catenate data */
          ret += file_write_field_array(file, options, ptable->List[index],
              NULL); /* and possibly write bin part */
          
          for (index_field=0; index_field < to_catenate.length; index_field++) {
            /* write catenated field data: rows x columns (but do not write bin reference yet) */
            struct  data_struct *field=(struct  data_struct *)(to_catenate.List[index_field]);
            if (strstr(options.format.Name,"IDL") && file.TxtHandle) fprintf(file.TxtHandle, ", $\n");
            /* write data set (text or binary) */
            file_write_field_array(file, options, *field,
              NULL);  /* and write the bin part if required, but not its reference */
            ptable->List[index].rows += field->rows;
            bin_field.rows           += field->rows;
            field->rows=0; /* unactivate */
          }
          /* now write the bin reference catenated part (only once) if required */
          end = options.use_binary && file.BinHandle ? 
                  ftell(file.BinHandle) : 0;
          if (end > 0) end--;
          /* write reference (TargetBin, start,end, length) in TxtHandle */
          length=end-start+1;
          if (file.BinHandle && file.TxtHandle) pfprintf(file.TxtHandle, options.format.BinReference, "slllll",
            file.TargetBin, /* 1 FIL */
            start,          /* 2 BEG */
            end,            /* 3 END */
            length,         /* 4 LEN */
            bin_field.rows,     /* 5 ROW */
            bin_field.columns); /* 6 COL */
          if (options.use_binary) options.use_binary=1; /* back to default binary mode */

        } /* end catenated fields (else) */
        /* end Data.Section part */

        /* special case for IDL */
        if (strstr(options.format.Name,"IDL") && file.TxtHandle) fprintf(file.TxtHandle, " ]\n");
        file_write_field_data(file, options, ptable->List[index], options.format.EndData);
      } /* if IDL empty else ... */
    } /* if rows columns within output range */
    /* free to_catenate, but not its elements (which are pointers to keep) */
    to_catenate.List=(char**)memfree(to_catenate.List);
    to_catenate.nalloc=to_catenate.length=0;
  } /* end for (index < ptable->index) */
  
  last_valid_name=str_free(last_valid_name);
  
  /* close current section (if any) */
  if (section_current && (strstr(options.format.Name,"IDL") || strcmp(section_current, ROOT_SECTION))) /* write section_end (if any) */
    file_write_section(file, options,
      section_current, options.format.EndSection);

  if (strstr(options.format.Name, "IDL") && file.TxtHandle) {
    /* transfert section names into returned structure */
    fprintf(file.TxtHandle, "%s = { %s:%s", file.RootName, section_names.List[0], section_names.List[0]);
    for (index=options.out_headers ? 0 : 1; index < section_names.length; index++) {
      if (options.out_headers) {
        fprintf(file.TxtHandle, ", Headers%s:Headers%s",
          section_names.List[index], section_names.List[index]);
        fprintf(file.TxtHandle, ", Data%s:Data%s",
          section_names.List[index], section_names.List[index]);
      } else
          fprintf(file.TxtHandle, ", %s:%s",
            section_names.List[index], section_names.List[index]);
    }
    fprintf(file.TxtHandle, "}\n");
  }
  section_current       = str_free(section_current);
  section_current_valid = str_free(section_current_valid);

  /* write output footer */
  file_write_headfoot(file, options, options.format.Footer);
  
  time(&EndTime);
  if (options.verbose >= 2)
    printf("VERBOSE[file_write_target]: time elapsed %g [s]\n", difftime(EndTime,StartTime));

  /* close Source file: done at end of function parse_files */

  if (options.verbose >= 2) {
    printf("VERBOSE[file_write_target]: file '%s': classify %ld section%s:\n", file.Source, section_names.length, section_names.length > 1 ? "s" : "");
    for (index=0; index < section_names.length; index++) {
      printf(" %s: {%s}\n",  section_names.List[index], section_fields.List[index]);
    }
  }
  
  /* we now must close Target TxT and Bin handles */
  if (file.BinHandle)    { 
    if(fclose(file.BinHandle)) 
      print_stderr( "Warning: Could not close output Binary file %s [looktxt:file_write_target:%d]\n",
        file.TargetBin,__LINE__);
    file.BinHandle=NULL; 
  }
  if (file.TxtHandle && file.TargetTxt 
   && strcmp(file.TargetTxt, "stdout") && strcmp(file.TargetTxt, "stderr")) {
#ifdef USE_MAT
    if (options.ismatnexus == 1 && file.mxRoot && mxIsStruct(file.mxRoot)) { 
      /* We open the MAT file. mode 'wz' does not work properly */
      MATFile *pmat  = matOpen(file.TargetTxt, "w7.3"); /* use HDF compression */
      if (!pmat) {
        print_stderr( "Warning: Could not open Matlab Binary file %s [looktxt:file_write_target:%d]\n",
        file.TargetTxt,__LINE__);
        ret=0;
      } else {
        /* write mxRoot to file and free it */
        if (options.verbose >= 2) {
          printf("VERBOSE[file_write_target]: writing file '%s'\n", file.TargetTxt);
        }
        if (file.mxData) mxSetField(file.mxRoot, 0, "Data", file.mxData);
        
        if (options.out_headers && file.mxHeaders) {
          mxSetField(file.mxRoot, 0, "Headers", file.mxHeaders);
        }
        
        if (matPutVariable(pmat, options.names_root ? 
          options.names_root : file.RootName, file.mxRoot))
          print_stderr("Error putting mxRoot\n");
        
        /* close the MAT file and free memory */
        if (matClose(pmat) != 0) {
          print_stderr( "Warning: Could not close Matlab Binary file %s [looktxt:file_write_target:%d]\n",
          file.TargetTxt,__LINE__);
          ret=0;
        }
        
        file.TxtHandle = NULL;
#ifdef USE_MEX
        file.mxRoot = file.mxHeaders = file.mxData = NULL; /* do not free */
#endif
      }
    } else
#ifdef USE_MEX
    if (file.TxtHandle && options.ismatnexus == 3) {
      if (file.mxRoot) {
        /* write mxRoot to file and free it */
        if (file.mxData) mxSetField(file.mxRoot, 0, "Data", file.mxData);
        if (options.out_headers && file.mxHeaders) {
          mxSetField(file.mxRoot, 0, "Headers", file.mxHeaders);
        }
      } else file.mxRoot = mxCreateDoubleMatrix(0,0, mxREAL);
      /* allocate the return value of the mex */
      if (options.file_index == 0 && options.sources_nb == 1) {
        mxOut = file.mxRoot;
      } else {
        if (options.file_index == 0)
          mxOut = mxCreateCellMatrix(1, options.sources_nb);
        /* transfer the mxRoot structure to the output cell array */
        mxSetCell(mxOut, options.file_index, file.mxRoot);
      }
      /* avoid freeing the blocks */
      file.mxData = file.mxHeaders = file.mxRoot=NULL; 
    } else
#endif
#endif
#ifdef USE_NEXUS
  if (file.TxtHandle && options.ismatnexus == 2) {
    NXclosegroup(file.nxHandle);
    if (NXclose(&(file.nxHandle)) == NX_ERROR)
      exit(print_stderr( "Warning: Could not close output NeXus/HDF file %s [looktxt:file_write_target:NXclose:%d]\n",
        file.TargetTxt,__LINE__));
    file.nxHandle=file.TxtHandle=NULL;
  } else
#endif /* USE_NEXUS */
    if(fclose(file.TxtHandle)) 
      print_stderr( "Warning: Could not close output Text file %s [looktxt:file_write_target:%d]\n",
        file.TargetTxt,__LINE__);
    file.TxtHandle=NULL; 
  }

  return(ret);
} /* file_write_target */

/*****************************************************************************
* parse_files: Parse input parameters looking for FILE names (non '-' options)
* returns the number of processed files (with scan_file)
*****************************************************************************/
int parse_files(struct option_struct options, int argc, char *argv[])
{
  int j;

  for(j = 0; j < options.sources_nb; j++) {
    struct file_struct  file;
    struct table_struct *table;
    char  *filename=NULL;
    int    i;

    i = options.files_to_convert_Array[j]; /* does the job for each file */

    filename = str_dup(argv[i]); /* get file name from arguments */

    /* open source file, and test for targets */
    file = file_open(filename, options);

    /* if Source file and Targets are available: scan source file */
    if (file.Source && file.TargetTxt
      && (!options.use_binary || file.TargetBin)) {
      table = file_scan(file, options);   /* scan: returns nb of extracted fields */
      if (options.verbose >= 2) printf("VERBOSE[parse_files]:       file '%s': found %ld numerical field%s\n", file.Source, table->length, table->length > 1 ? "s" : "");
      if (table->nalloc && table->length) { /* if some data structures where extracted */
        struct write_struct found_sections = file_write_getsections(file, options, table);
        /* if (options.verbose >= 3) table_print(table); */
        long ret=file_write_target(file, options, table, found_sections.section_names, found_sections.section_fields);
        /* Free section structures */
        found_sections.section_names =strlist_free(found_sections.section_names);
        found_sections.section_fields=strlist_free(found_sections.section_fields);
        if (options.verbose >= 1) print_stderr("Looktxt: file '%s': wrote %ld numerical field%s into %s\n", 
          file.Source, ret, ret > 1 ? "s" : "", file.TargetTxt);
      }
      options.file_index++;
      table=table_free(table);
      free(table); table=NULL;
    }
    fflush(NULL); /* flush all */
    file=file_close(file);
    filename=str_free(filename);
  } /* for i */

  return(options.file_index);
} /* parse_files */

/*****************************************************************************
* options_parse: Parse input parameters starting with '-' sign (OPTIONS)
* returns the option structure
*****************************************************************************/
struct option_struct options_parse(struct option_struct options, int argc, char *argv[])
{
  #define BUFFER_SIZE 32*1024
  int  i;
  char  tmp0[256];
  char  tmp1[256];
  char  tmp2[256];
  char  tmp3[BUFFER_SIZE];
  char  tmp4[BUFFER_SIZE];
  char *tmp5=NULL;
  char *tmp6=NULL;
  char  tmp7[256];
  char  tmp8[BUFFER_SIZE];

  /* init section */
  for (i=0; i<MAX_LENGTH; i++) {
    options.files_to_convert_Array[i] = 0;
  }

  for(i = 1; i < argc; i++)
  {
    if(!strcmp("-h", argv[i]))
      print_usage(argv[0], options);
    else if(!strcmp("--help",      argv[i]))
      print_usage(argv[0], options);
    else if(!strcmp("--version",      argv[i]))
    { print_version(argv[0]); exit(EXIT_SUCCESS); }
    else if(!strcmp("--append",      argv[i]))
    { options.openmode[0]= 'a'; options.force = 1; }
    else if(!strncmp("--struct=", argv[i], 9)) {
      char *struct_char=NULL;
      if (strlen(argv[i]) > 9)
        if (strcmp(&argv[i][9], "NULL") && strcmp(&argv[i][9], "0"))
          struct_char = str_dup(&argv[i][9]);
      if (!struct_char) options.use_struct = '\0';
      else {
        options.use_struct = struct_char[0];
        struct_char=str_free(struct_char);
      }
    } else if(!strcmp("--struct",    argv[i]))
      options.use_struct = '.';
    else if(!strcmp("--binary",    argv[i]) || !strcmp("-b",    argv[i]))
      options.use_binary = 1;
    else if(!strcmp("--headers",    argv[i]) || !strcmp("-H",     argv[i]))
      options.out_headers= 1;
    else if(!strncmp("--headers=",    argv[i], 10))
      options.out_headers= atoi(&argv[i][10]);
    else if(!strcmp("--force",     argv[i]) || !strcmp("-F",     argv[i]))
      options.force      = 1;
    else if(!strcmp("--fast",      argv[i]))
      options.fast       = 1;
    else if(!strncmp("--fast=",     argv[i],7))
      options.fast       = atoi(&argv[i][7]);
    else if(!strcmp("--verbose",   argv[i]) || !strcmp("-v",   argv[i]))
      options.verbose    = 2;
    else if(!strncmp("--verbosity=",   argv[i], 12))
      options.verbose    = atoi(&argv[i][12]);
    else if(!strcmp("--debug",     argv[i]))
      options.verbose    = 3;
    else if(!strcmp("--silent",    argv[i]))
      options.verbose    = 0;
    else if(!strcmp("--metadata-only",    argv[i]))
      options.metadata_only = 1;
    else if(!strcmp("--test",    argv[i]))
      options.test       = 1;
    else if(!strcmp("--catenate",  argv[i]) || !strcmp("-c",  argv[i]))
      options.catenate   = 1;
    else if(!strncmp("--catenate=",  argv[i],11) )
      options.catenate   = atoi(&argv[i][11]);
    else if(!strcmp("--fortran",   argv[i]) || !strcmp("--wrapped",   argv[i]))
      options.fortran    = 1;
    else if(!strncmp("--fortran=",  argv[i],10) )
      options.fortran   = atoi(&argv[i][11]);
    else if(!strncmp("--section=", argv[i], 10))
      strlist_add(&(options.sections), &argv[i][10]);
    else if(!strncmp("--makerows=", argv[i], 11))
      strlist_add(&(options.makerows), &argv[i][11]);
    else if((!strcmp("--section",   argv[i]) || !strcmp("-s",   argv[i])) && (i + 1) <= argc)
      strlist_add(&(options.sections), argv[++i]);
    else if(!strcmp("--makerows",   argv[i]) && (i + 1) <= argc)
      strlist_add(&(options.makerows), argv[++i]);
    else if(!strncmp("--metadata=", argv[i], 11))
      strlist_add(&(options.metadata), &argv[i][11]);
    else if((!strcmp("--metadata",   argv[i]) || !strcmp("-m",   argv[i])) && (i + 1) <= argc)
      strlist_add(&(options.metadata), argv[++i]);

    else if(!strncmp("--comment=", argv[i], 10)) {
      str_free(options.comment);
      if (strcmp(&argv[i][10],"NULL"))
        options.comment = str_dup(&argv[i][10]);
      else
        options.comment = str_dup("");
    } else if(!strcmp("--comment", argv[i]) && (i + 1) <= argc) {
      str_free(options.comment);
      if (strcmp(argv[++i],"NULL"))
        options.comment = str_dup(argv[++i]);
      else
        options.comment = str_dup("");
    } else if(!strncmp("--eol=",   argv[i], 6)) {
      str_free(options.eol);
      if (strcmp(&argv[i][6],"NULL"))
        options.eol = str_dup(&argv[i][6]);
      else
        options.eol = str_dup("");
    } else if(!strcmp("--eol",     argv[i]) && (i + 1) <= argc) {
      str_free(options.eol);
      if (strcmp(&argv[i][6],"NULL"))
        options.eol = str_dup(argv[++i]);
      else
        options.eol = str_dup("\n");
    } else if(!strncmp("--separator=", argv[i], 12)) {
      str_free(options.separator);
      if (strcmp(&argv[i][12],"NULL"))
        options.separator = str_dup(&argv[i][12]);
      else
        options.separator = str_dup("");
    } else if(!strcmp("--separator",   argv[i]) && (i + 1) <= argc) {
      str_free(options.separator);
      if (strcmp(argv[++i],"NULL"))
        options.separator = str_dup(argv[++i]);
      else
        options.separator = str_dup("");
    } else if(!strncmp("--outfile=", argv[i], 10))
      options.outfile = fileparts(&argv[i][10]);
    else if((!strcmp("--outfile",   argv[i]) || !strcmp("-o",   argv[i])) && (i + 1) <= argc)
      options.outfile = fileparts(argv[++i]);
    else if(!strncmp("--format=",  argv[i], 9)) {
      format_free(options.format);
      options.format = format_init(Global_Formats, &argv[i][9]);
    } else if((!strcmp("--format",  argv[i]) || !strcmp("-f",  argv[i])) && (i + 1) <= argc) {
      format_free(options.format);
      options.format = format_init(Global_Formats, argv[++i]);
    } else if(!strncmp("--nelements_min=",  argv[i], 16)) {
      options.nelements_min = atoi(&argv[i][16]);
    } else if(!strcmp("--nelements_min",  argv[i]) && (i + 1) <= argc) {
      options.nelements_min = atoi(argv[++i]);
    } else if(!strncmp("--nelements_max=",  argv[i], 16)) {
      options.nelements_max = atoi(&argv[i][16]);
    } else if(!strcmp("--nelements_max",  argv[i]) && (i + 1) <= argc) {
      options.nelements_max = atoi(argv[++i]);

    } else if(!strncmp("--names_length=",  argv[i], 15)) {
      options.names_length = atoi(&argv[i][16]);
    } else if(!strcmp("--names_length",  argv[i]) && (i + 1) <= argc) {
      options.names_length = atoi(argv[++i]);
    } else if(!strcmp("--names_lower", argv[i]))
      options.names_lowup= 'l';
    else if(!strcmp("--names_upper", argv[i]))
      options.names_lowup= 'u';
    else if(!strncmp("--names_root=", argv[i], 13)) {
      char *root_char=NULL;
      if (strlen(argv[i]) > 13)
        if (strcmp(&argv[i][13], "NULL") && strcmp(&argv[i][13], "0")) {
          char *tmp9=NULL;
          char *tmp10=NULL;
          tmp9 = str_reverse(&argv[i][13]);
          tmp10 = str_valid(tmp9, options.names_length);
          root_char = str_reverse(tmp10);        /* default */
          str_free(tmp9); str_free(tmp10);
        }
      options.names_root = root_char ? root_char : str_dup("NULL");
    } else if(argv[i][0] == '-') {
      print_stderr( "Warning: Invalid %d-th option %s. Ignoring [looktxt:options_parse:%d]\n", 
        i, argv[i],__LINE__);
    } else if(argv[i][0] != '-') {
      /* convert argv[i]: store index of argument */
      if (options.sources_nb < MAX_LENGTH)
        options.files_to_convert_Array[options.sources_nb++] = i;
      else print_stderr( "Warning: Exceeding maximum number of files to process (%d) for file '%s'. Ignoring [looktxt:options_parse:%d]\n", 
        MAX_LENGTH, argv[i],__LINE__);
    } else
      print_usage(argv[0], options);
  } /* for i */
  
  /* check again for binary */
  if (!options.use_binary)
    options.use_binary = strstr(options.format.Name, "binary") ? 1 : 0;
  
#ifdef USE_MEX
  if (strstr(options.format.Name, "MEX")) {
    options.ismatnexus = 3;
    options.use_binary = 0;
  }
#endif
#ifdef USE_MAT
  if (strstr(options.format.Name, "MAT") && !strstr(options.format.Name, "Matlab")) {
    options.ismatnexus = 1;
    options.use_binary = 0;
    /* a variable name is required for MAT export */
    if (options.names_root && !strcmp(options.names_root, "NULL"))
      options.names_root = str_free(options.names_root);
  } 
#endif
#ifdef USE_NEXUS
  if (strstr(options.format.Name, "HDF")) {
    options.ismatnexus = 2;
    options.use_binary = 0;
  }
#endif
  if (options.ismatnexus) options.use_struct=0;

  /* format dependent options */
  /* Matlab, Octave and Scilab require --struct=. */
  if (strstr(options.format.Name, "Matlab")
    ||  strstr(options.format.Name, "Scilab")
    ||  strstr(options.format.Name, "Octave"))
    if (options.use_struct != '.') {
      if (options.verbose >= 2)
      print_stderr( "Warning: Format %s requires structures. Now setting --struct='.' [looktxt:options_parse:%d]\n", 
        options.format.Name,__LINE__);
      options.use_struct = '.';
    }
  /* IDL does not support structures fully. If used, replace by _ */
  if (strstr(options.format.Name, "IDL") && options.use_struct) {
    if (options.verbose >= 2)
    print_stderr( "Warning: Format %s does not support fully structures. Now unsetting --struct [looktxt:options_parse:%d]\n", 
      options.format.Name,__LINE__);
     options.use_struct = 0;
  }

  if (options.names_root && !strcmp(options.names_root,"NULL") 
  && (strstr(options.format.Name, "Matlab")
    ||  strstr(options.format.Name, "Scilab")
    ||  strstr(options.format.Name, "Octave")
    ||  strstr(options.format.Name, "IDL")))
    if (options.verbose >= 1)
    print_stderr( "Warning: NULL root name is NOT recommanded with format %s [looktxt:options_parse:%d]\n", 
      options.format.Name,__LINE__);

  /* build the option list string */
  sprintf(tmp0, " --nelements_min=%ld --nelements_max=%ld --names_length=%d",
    options.nelements_min, options.nelements_max, options.names_length);

  if (options.use_struct)
    sprintf(tmp1, " --struct=%c",options.use_struct);
  else sprintf(tmp1, " --struct=NULL");

  if (options.outfile.FullName)
    sprintf(tmp2, " --outfile=\"%s\"",options.outfile.FullName);
  else strcpy(tmp2, "");

  strcpy(tmp3, ""); /* build list of sections */
  for (i=0; i < options.sections.length; i++)
  { /* scan all registered sections */
    char this_section[256];
    if (options.sections.List[i]) {
      sprintf(this_section, " --section=\"%s\"", options.sections.List[i]);
    if (strlen(tmp3)+strlen(options.sections.List[i]) < BUFFER_SIZE)
      strcat(tmp3, this_section);
    else if (options.verbose >= 2)
      print_stderr( "Warning: Exceeding maximum section buffer size (%d) for section %s. Ignoring. [looktxt:options_parse:%d]\n", 
        BUFFER_SIZE, this_section,__LINE__);
    }
  }

  strcpy(tmp4, ""); /* build list of metadata */
  for (i=0; i < options.metadata.length; i++)
  { /* scan all registered sections */
    char this_section[256];
    if (options.metadata.List[i]) {
      sprintf(this_section, " --metadata=\"%s\"", options.metadata.List[i]);
      if (strlen(tmp4)+strlen(options.metadata.List[i]) < BUFFER_SIZE)
        strcat(tmp4, this_section);
      else if (options.verbose >= 2)
        print_stderr( "Warning: Exceeding maximum metadata buffer size (%d) for metadata %s. Ignoring [looktxt:options_parse:%d]\n", 
          BUFFER_SIZE, this_section,__LINE__);
    }
  }

  strcpy(tmp8, ""); /* build list of metadata */
  for (i=0; i < options.makerows.length; i++)
  { /* scan all registered sections */
    char this_section[256];
    if (options.makerows.List[i]) {
      sprintf(this_section, " --makerows=\"%s\"", options.makerows.List[i]);
      if (strlen(tmp8)+strlen(options.makerows.List[i]) < BUFFER_SIZE)
        strcat(tmp8, this_section);
      else if (options.verbose >= 2)
        print_stderr( "Warning: Exceeding maximum makerows buffer size (%d) for metadata %s. Ignoring [looktxt:options_parse:%d]\n", 
          BUFFER_SIZE, this_section,__LINE__);
    }
  }
  #undef BUFFER_SIZE

  tmp5 = str_quote(options.eol);
  tmp6 = str_quote(options.separator);

  if (options.names_root)
    sprintf(tmp7, "--names_root=%s", options.names_root);
  else strcpy(tmp7, "");

  options.option_list = str_cat(
    options.pgname,
    options.out_headers ?  " --headers"    : "",
    options.out_table ?    " --table"      : "",
    options.force ?        " --force"      : "",
    options.verbose == 0 ? " --silent"     : "",
    options.verbose == 2 ? " --verbose"    : "",
    options.verbose == 3 ? " --debug"      : "",
    options.test == 1 ?    " --test"       : "",
    options.catenate ?     " --catenate"   : " --catenate=0",
    options.fortran ?      " --fortran"    : " --fortran=0",
    options.use_binary ?   " --binary"     : "",
    options.fast ?         " --fast"       : "",
    options.openmode[0]=='a' ? " --append" : "",
    options.names_lowup == 'l' ?  " --names_lower": "",
    options.names_lowup == 'u' ?  " --names_upper": "",
    tmp7,
    " --comment=\"",     strlen(options.comment) ? options.comment : "NULL",
    "\" --eol=\"",       strlen(tmp5) ? tmp5 : "NULL",
    "\" --separator=\"", strlen(tmp6) ? tmp6 : "NULL",
    "\" --format=\"",    options.format.Name, "\"",
    tmp0, /* nelements */
    tmp1, /* struct */
    tmp2, /* outfile */
    tmp3, /* sections */
    tmp4, /* metadata */
    tmp8, /* makerows */
    NULL);
  if (options.verbose >= 2)
      printf("\nVERBOSE[options_parse]: Command line=%s\n", options.option_list);
  str_free(tmp5); str_free(tmp6);

  return(options);
} /* options_parse */

/*****************************************************************************
* main: Entry point
* returns the number of processed file
  if (options.verbose >= 3)
    printf("DEBUG[main                ]: Starting %s\n", argv[0]);
s (with scan_file)
*****************************************************************************/
int main(int argc, char *argv[])
{
  struct option_struct options;
  long   ret=0;

#ifdef MAC
  argc = ccommand(&argv);
#endif

  /* init default struct option_struct */
  options = options_init(argv[0]);

  /* parse options and store them */
  options = options_parse(options, argc, argv);

  if (options.verbose >= 3)
    printf("DEBUG[main:options_init  ]: Starting %s with %d options\n", argv[0], argc);

  if (!options.sources_nb) {
    print_stderr( "Warning: No file to process\n");
    print_stderr( "         Type 'looktxt --help' for help.\n");
    return(0);
  }

  /* re-read program arguments and calls 'scan_file' for each file name */
  ret = parse_files(options, argc, argv);

  /* Free options */
  options=options_free(options);

  /* returns number of processed files */
  if (options.test) ret=0;
  return((int)ret);

} /* main */

/* interface with Matlab */
#ifdef USE_MEX
/* contributed code argv/argc interface from James Tursa
   http://www.mathworks.com/matlabcentral/newsreader/view_thread/160255
 */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs,
     const mxArray *prhs[])
{
  char *argv[MAX_LENGTH];   /* build a fake argv array */
  int   argc = 1;
  int   i    = 0;
  
  /* set program name argv[0] */
  argv[0] = (char*)mxMalloc(MAX_LENGTH);
  if (!argv[0]) {
    mexPrintf("looktxt/mex : argument %i. Size %i\n", 0, MAX_LENGTH);
    mexErrMsgTxt("looktxt/mex : can not allocate program name string argv[0].\n");
  }
  strcpy(argv[0],"looktxt");

  /* check in/out parameters */
  if (nlhs > 1)
	  mexErrMsgTxt("looktxt : Too many output arguments (1 max).");

  /* allocate memory and parse input arguments (tokens from string arguments) */
  for (i = 0; i < nrhs; i++)
  { 
    char *InputString;
    
    if (mxIsChar(prhs[i]) != 1) /* must be a char */
    {
      mexPrintf("looktxt/mex : argument %i (%s)\n", i, mxGetClassName(prhs[i]));
      mexErrMsgTxt("looktxt/mex : Input should be strings.\n");
    }
    /* read the input argument and return it as a string */
    InputString = mxArrayToString(prhs[i]);
    if (!InputString) {
      mexPrintf("looktxt/mex : argument %i. InputString=NULL\n", i);
      mexErrMsgTxt("looktxt/mex : can not get input parameter.\n");
    }
    
    /* transfer the word into allocated argv[] */
    argv[argc] = (char*)mxMalloc(strlen(InputString)+64);
    if (argv[argc] == NULL) {
      mexPrintf("looktxt/mex : argument %i. Size %i\n", argc, strlen(InputString));
      mexErrMsgTxt("looktxt/mex : can not allocate memory for input argument string.\n");
    }
    strcpy(argv[argc], InputString);
    argc++;
    
    mxFree(InputString);

  } /* end for nrhs (all input string arguments) */
  
  /* call 'main' */
  i = main(argc, argv);
  /* send back the mxOut array */

  if (i && nlhs) {
    if (!mxOut)   plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    else        { plhs[0] = mxOut; }
  } else {
    if (nlhs) plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
  }
  /* all allocated blocks are freed by Matlab API automatically */
  /* no need to call ANY free, mxFree, mxDestroyArray */

} 
#endif
