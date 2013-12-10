/* program cif2hkl */
/* compile with:
      mex -c -O cif2hkl.F90
      mex -O cif2hkl_mex.c cif2hkl.o -o cif2hkl -lgfortran
   get single executable
      gfortran -O2 -o cif2hkl cif2hkl.o -lm
 */


#ifdef MATLAB_MEX_FILE
#ifndef USE_MEX
#define USE_MEX
#endif
#endif

#ifdef  USE_MEX
#include <mex.h>	   /* include MEX library for Matlab */
#endif
#include <string.h>

#define MAX_LENGTH 1024   /* length of buffer */

#ifdef USE_MEX
void mexFunction(int nlhs, mxArray *plhs[], int nrhs,
     const mxArray *prhs[])
{
  char   file_in[MAX_LENGTH];
  char   file_out[MAX_LENGTH];
  char   mode[MAX_LENGTH];
  double lambda = 1.0;
  long   verbose= 0;
  int    i      = 0;
  char   *message;
  
  /* input arguments:
   *        file_in, file_out, lambda, mode, verbose
   */
  
  if(nrhs == 0)
    mexErrMsgTxt("At least one string input required. Syntax: cif2hkl(file_in, file_out, lambda, mode, verbose)");
  
  /* create output buffer */
  message = mxCalloc(4096, sizeof(char));
  if(message == NULL) 
    mexErrMsgTxt("Not enough memory to create result string.");
  for (i=0; i<4095; message[i++]=' '); message[4095]='\0';
  
  /* prhs[0] = file_in: must be non empty */
  if (!mxIsChar(prhs[0]))
    mexErrMsgTxt("At least one string input required: cif2hkl('cif/cfl/pcr/shelX file name')");
  strncpy(file_in,  mxArrayToString(prhs[0]), MAX_LENGTH);
  if (!strlen(file_in) || !strcmp(file_in,"-h") || !strcmp(file_in,"--help"))
    { 
      print_usage_("cif2hkl", message);
      for (i=4095; i>0; i--)
        if (message[i] != ' ' && message[i] != '\0') break;
      message[i]='\0';
      mexPrintf("%s\n", message); 
      return; 
    }
  if (!strcmp(file_in,"-v") || !strcmp(file_in,"--version"))
    { 
      print_version_("cif2hkl", message);
      for (i=4095; i>0; i--)
        if (message[i] != ' ' && message[i] != '\0') break;
      message[i]='\0';
      mexPrintf("%s\n", message); 
      return; 
    }
  if (nrhs >= 2 && mxIsChar(prhs[1]) && mxGetNumberOfElements(prhs[1]))
    strncpy(file_out, mxArrayToString(prhs[1]), MAX_LENGTH);
  else
    sprintf(file_out, "%s.hkl", file_in);
  
  if (nrhs >= 3 && mxIsDouble(prhs[2]) && mxGetNumberOfElements(prhs[2])==1)
    lambda = mxGetScalar(prhs[2]);
    
  if (nrhs >= 4 && mxIsChar(prhs[3]) && mxGetNumberOfElements(prhs[3]))
    strncpy(mode, mxArrayToString(prhs[3]), MAX_LENGTH);
  else
    strcpy(mode, "p");
    
  if (nrhs >= 5)
    verbose = (int)mxGetScalar(prhs[4]);
    
  /* C to Fortran string conversion: pad with spaces until end of allocation */
  for (i=strlen(file_in); i<MAX_LENGTH; file_in[i++]=' ');
  for (i=strlen(file_out); i<MAX_LENGTH; file_out[i++]=' ');
  for (i=strlen(mode); i<MAX_LENGTH; mode[i++]=' ');
    
  /* call the Fortran code */
  cfml_cif2hkl_(file_in, file_out, &lambda, mode, &verbose, message);
  
  /* do a trim starting from end of message (search for non space) */
  for (i=4095; i>=0; i--)
    if (message[i] != ' ' && message[i] != '\0') break;
  message[i]='\0';
  if (strlen(message) && message[0] != ' ' && message[1] != ' ') {
    if (nlhs)
      plhs[0] = mxCreateString(message);
    else
      mexPrintf("%s\n", message);
  } 
  else
    plhs[0] = mxCreateString("");
  
} 
#endif


