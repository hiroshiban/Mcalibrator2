#!/usr/bin/env python

""" A python module for raw communication with Matlab(TM) using pipes under
unix.

This module exposes the same interface as mlabraw.cpp, so it can be used along
with mlabwrap.py.
The module sends commands to the matlab process using the standard input pipe.
It loads data from/to the matlab process using the undocumented save/load stdio
commands. Only unix (or mac osx) versions of Matlab support pipe communication,
so this module will only work under unix (or mac osx).

Author: Dani Valevski <daniva@gmail.com>
Dependencies: scipy
Tested Matlab Versions: 2009b, 2010a, 2010b, 2011a
License: MIT

Limitations:
as it uses pipe with matlab save stdio, only Matlab v4 types can be transferred,
that is strings, scalars, vectors and 2D matrices...
Modification can only be done through a save to file 


Usage:
>>>> from matlabpipe import MatlabPipe
>>>> mp=MatlabPipe(matlab_process_path='/opt/MATLAB/R2010a/bin/matlab')
>>>> mp.open()
>>>> mp.eval('a=[ 1 2 3 4 ]; plot(a);')
>>>> b = mp.get('a');
"""

from cStringIO import StringIO
import fcntl
import numpy as np
import os
import scipy.io as mlabio
import select
import subprocess
import sys
import tempfile
import time

class MatlabError(Exception):
  """Raised when a Matlab evaluation results in an error inside Matlab."""
  pass

class MatlabConnectionError(Exception):
  """Raised for errors related to the Matlab connection."""
  pass

def which(program):
    def is_exe(fpath):
        return os.path.exists(fpath) and os.access(fpath, os.X_OK)

    def ext_candidates(fpath):
        yield fpath
        for ext in os.environ.get("PATHEXT", "").split(os.pathsep):
            yield fpath + ext

    fpath, fname = os.path.split(program)
    if fpath:
        if is_exe(program):
            return program
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            exe_file = os.path.join(path, program)
            for candidate in ext_candidates(exe_file):
                if is_exe(candidate):
                    return candidate

    return None

def find_matlab_process(binary='guess'):
  """"Tries to guess Matlab/iFit process path."""
  if binary == None or binary == 'guess':
    w = which('matlab')
    if w is None:
      w = which('ifit')
    return w
  else:    
    return which(binary)


def find_matlab_version(matlab_version):
  """Tries to guess Matlab's version according to its process path.
  If we couldn't guess the version, None is returned."""
  if not is_valid_version_code(matlab_version):
      version = None
  return version

def is_valid_version_code(version):
  """ Checks that the given version code is valid.
  """
  return version != None and len(version) == 5 and \
      int(version[:4]) in range(1990, 2050) and \
      version[4] in ['h', 'g', 'f', 'e', 'd', 'c', 'b', 'a']

class MatlabPipe(object):
  """ Manages a connection to a Matlab process.
  
  To instantiate a connection to Matlab, use e.g.:
    mp=MatlabPipe(matlab_process_path='/opt/MATLAB/R2010a/bin/matlab',
      matlab_version='2010a')
  The process can then be opened and closed with the open/close methods.
    mp.open()
  To send a command to the Matlab shell use 'eval'.
    mp.eval('Matlab expression')
  To load numpy data (in a dict) to the Matlab shell use 'put'
    mp.put({'A' : [1, 2, 3]})
  To retrieve numpy data from the Matlab shell use 'get'.
    ndarray = mp.get('Matlab_variable')
  """

  def __init__(self, matlab_process_path=None, matlab_version=None, use_pipe=None):
    """ Initialises the class.

    Input:
      matlab_process_path: None (to guess with 'which') or path to Matlab executable (string)
      matlab version:      in the format [YEAR][VERSION] for example: 2011a (string)
      use_pipe:            when true, will favour data exchange with pipes, else use temporary files
                           When pipes fail, the temporary file method is used.
                           When set to None, pipe is preferred under Linux/MaxOSX
    """
    if matlab_process_path == 'guess':
      matlab_process_path = find_matlab_process()
    if matlab_version == 'guess':
      matlab_version = find_matlab_version(matlab_process_path)
    #print 'Matlab version %s' % matlab_version
    print 'Matlab path    %s' % matlab_process_path
    if not is_valid_version_code(matlab_version):
    #  print 'Invalid version code %s, defaulting to 2010a' % matlab_version
      matlab_version = '2010a'
    if not os.path.exists(matlab_process_path):
      raise ValueError('Matlab process path %s does not exist' % matlab_process_path)
    self.matlab_version = (int(matlab_version[:4]), matlab_version[4])
    self.matlab_process_path = matlab_process_path
    self.process             = None
    self.command_end_string  ='___MATLAB_PIPE_COMMAND_ENDED___'
    self.expected_output_end = '%s\n>>' % self.command_end_string
    self.stdout_to_read      = ''
    if use_pipe == None:
      if sys.platform.startswith('win'):
        self.use_pipe            = False  # not supported under Windows
      else:
        self.use_pipe            = True
    else:
      self.use_pipe = use_pipe
    # end __init__

  def open(self, print_matlab_welcome=True):
    """ Opens the Matlab process.
    
    Input:
      print_matlab_welcome: indicate if Matlab welcome should be shown (True/False)
    """
    if self.process and not self.process.returncode:
      raise MatlabConnectionError('Matlab(TM) process is still active.'
        'Use MatlabPipe.close to close it.')
    # remove '-nojvm' from Popen arguments to allow better Java widgets
    if 'matlab' in self.matlab_process_path:
      self.process = subprocess.Popen(
        [self.matlab_process_path, '-nodesktop','-nosplash'],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    elif 'ifit' in self.matlab_process_path:
      """currently broken as the pipe does not seem functional with ifit"""
      self.process = subprocess.Popen(
        [self.matlab_process_path],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    flags = fcntl.fcntl(self.process.stdout, fcntl.F_GETFL)
    fcntl.fcntl(self.process.stdout, fcntl.F_SETFL, flags| os.O_NONBLOCK)
    
    if print_matlab_welcome:
      self._sync_output()
    else:
      self._sync_output(None)
    # end open

  def close(self):
    """ Closes the Matlab process.
    """
    self._check_open()
    self.process.stdin.write('exit')
    self.process.stdin.write('\n')
    self.process.stdin.close()

  def eval(self,
           expression,
           identify_errors=True,
           print_expression=False,
           on_new_output=sys.stdout.write):
    """ Evaluates a matlab expression synchronously.
    
    Input:
      expression: to be evaluated (string)
      identify_errors: report Matlab errors (True/False)
      print_expression: display expression to be evaluated (True/False)
      on_new_output: function called to print Matlab evaluation result (function=sys.stdout.write)
      
    The return value of the function is the Matlab output following the call.
    """
    self._check_open()
    if print_expression:
      print expression
    self.process.stdin.write(expression)
    self.process.stdin.write('\n')
    ret = self._sync_output(on_new_output)
    # TODO(dani): Use stderr to identify errors.
    if identify_errors and ret and ret.rfind('???') != -1 and ret.rfind('Warning') != -1:
      begin = ret.rfind('???') + 4
      end = ret.find('\n', begin)
      raise MatlabError(ret[begin:end])
    return ret
    # end eval


  def put(self, names_to_put, oned_as='row', on_new_output=None, use_pipe=None):
    """ Sends a dictionary of variable names into the Matlab shell.
    
    Input:
      names_to_put:  a dictionary containing variables or single variable to send
      oned_as:       'row' or 'column' to orient 1D arrays, or None.
      on_new_output: function called to print Matlab evaluation result (function=sys.stdout.write)
    """
    self._check_open()
    
    if use_pipe == None:
      use_pipe=self.use_pipe

    # attempt to use stdio to Matlab for sending the data
    # load stdio may only supports strings, scalars, vectors, 2D Matrix (may fail)
    success = False
    
    if use_pipe:
      try:
        # We can't give stdin to mlabio.savemat because it needs random access :(
        # initiate a buffer
        temp = StringIO()
        # save MAT into the buffer
        mlabio.savemat(temp, names_to_put, oned_as=oned_as)
        temp.seek(0)
        # get the content of the buffer
        temp_str = temp.read()  
        # tell Matlab to expect data from stdin
        self.process.stdin.write('load stdio;\n')
        # Matlab then issue message 'flushed_stdout' \n 'ack load stdio'
        self._read_until('ack load stdio\n', on_new_output=on_new_output)
        # send the buffer, as Matlab is ready to read it
        self.process.stdin.write(temp_str)
        # wait for actual processing acknowledgement by Matlab
        self._read_until('ack load finished\n', on_new_output=on_new_output)
        temp.close()
        success = True
      except:
        pass
        
    # if the stdio could not be used (failed, or not requested), go for temporary files
    if not success:
       # send data using temporary files
       temp = tempfile.NamedTemporaryFile(prefix='pymat_',suffix='.mat')
       # save MAT to temp
       mlabio.savemat(temp.name, names_to_put, oned_as=oned_as)
       # request Matlab to read that file
       self.process.stdin.write("load('%s');\n" % temp.name)
       # wait for completion of load
       self._sync_output(on_new_output=on_new_output)
       # close and delete the temporary file is done by garbage collector
       temp.close()
       
    self._sync_output(on_new_output=on_new_output)
    # end put

  def get(self,
          names_to_get,
          convert_to_numpy=True,
          on_new_output=None,use_pipe=None):
    """ Loads the requested variables from the Matlab shell.
    Matlab objects are returned as structures/dictionaries or numpy arrays.
    
    Input:
      names_to_get:  a list or single variable name to retrieve
                     or None to get all variables
      convert_to_numpy: convert arrays to numpy (True/False)
      on_new_output: function called to print Matlab evaluation result (function=sys.stdout.write)
    """
    self._check_open()
    
    if use_pipe == None:
      use_pipe=self.use_pipe
      
    single_item = isinstance(names_to_get, (unicode, str))
    if single_item:
      names_to_get = [names_to_get]

    # attempt to use a pipe to Matlab for retrieving the data
    # save stdio only supports strings, scalars, vectors, 2D Matrix. It may fail.
    success = False
    
    if use_pipe:
      # request Matlab to save data into the pipe (stdio)
      if names_to_get == None:
        # request Matlab to stream all variables using pipe 
        # (we specify -v7 but it actually only generates -v4)
        try:
          self.process.stdin.write('save -v7 stdio;\n')
          success = True
        except:
          pass
      else:
        # we want a selection of variables
        # Make sure that we throw an exception if the names are not defined.
        for name in names_to_get:
          self.eval('%s;' % name, print_expression=False, on_new_output=on_new_output)
        try:
          # request Matlab to stream selected variables using pipe
          # (we specify -v7 but it actually only generates -v4)
          self.process.stdin.write(
            "save('stdio', '-v7', '%s');\n" % '\', \''.join(names_to_get))
          success = True
        except:
          pass
          
    if success and use_pipe:
      # stdio seems to work, we now read the pipe stream
      # We have to read to a temp buffer because mlabio.loadmat needs
      # random access :(
      # the 'start_binary' is written at the beginning of the stdio stream
      self._read_until('start_binary\n', on_new_output=on_new_output)
      temp_str = self._sync_output(on_new_output=on_new_output) # read stdio stream
      # Remove expected output and "\n>>"
      # TODO(dani): Get rid of the necessary copy.
      # since R2010a MATLAB adds an extra >> so we need to remove more spaces.
      if self.matlab_version >= (2010, 'a'):
        temp_str = temp_str[:-len(self.expected_output_end)-6]
      else:
        temp_str = temp_str[:-len(self.expected_output_end)-3]
      temp = StringIO(temp_str)
      # evaluate pipe content to get the included variables
      try:
        ret = mlabio.loadmat(temp, chars_as_strings=True, squeeze_me=True, struct_as_record=True)
      except:
        success=False
      # clear pipe stream
      temp.close()
      
    if not success:
      # stdio did not work, or not requested: we use temporary files
      temp = tempfile.NamedTemporaryFile(prefix='pymat_',suffix='.mat')
      if names_to_get == None:
        # request Matlab to save to temporary file
        self.process.stdin.write("save('-v7','%s');\n" % temp.name)
      else:
        # request Matlab to save selected variables using temporary file
        self.process.stdin.write(
            "save('-v7', '%s', '%s');\n" % (temp.name, '\', \''.join(names_to_get)) )
      # wait for completion of save to file      
      self._sync_output(on_new_output=on_new_output)
      # evaluate temporary file content to get the included variables
      ret = mlabio.loadmat(temp.name, chars_as_strings=True, squeeze_me=True, struct_as_record=True)
      # close temporary file
      temp.close()

    # scan returned variables and convert them to ndarray when requested
    # Matlab struct  send tuple: -> no shape, len is number of fields
    #        cell:   send ndarray, len(shape) > 1, shape contains rows, columns, ... lengths -> tolist()
    #        vector: send ndarray, len(shape) == 1, shape is numel -> tolist()
    #        matrix: send ndarray, len(shape) > 1, shape contains rows, columns, ... lengths -> tolist()
    #        scalar: send float (OK) 
    #        string: send string (OK)
    for key in ret.iterkeys():
      if isinstance(ret[key], np.ndarray) and ret[key].shape and ret[key].shape[-1] == 1:
        ret[key] = ret[key][0] # get element from scalar ndarray
      if convert_to_numpy and isinstance(ret[key], np.ndarray):
        if isinstance(ret[key].tolist(), (unicode, str)):# Matlab single String
          ret[key] = ret[key].tolist()
        elif ret[key].dtype.kind == 'O':                 # Matlab Cell
          ret[key] = ret[key].tolist()
        elif isinstance(ret[key], list):                 # Python list
          ret[key] = np.array(ret[key])
          
    # when only one item, get first element of returned array
    if single_item:
      return ret[names_to_get[0]]
    return ret
    # end get
    
  # ============================================================================  

  def _check_open(self):
    if not self.process or self.process.returncode:
      raise MatlabConnectionError('Matlab(TM) process is not active.')

  def _read_until(self, wait_for_str, on_new_output=sys.stdout.write):
    all_output = StringIO()
    output_tail = self.stdout_to_read
    while not wait_for_str in output_tail:
      tail_to_remove = output_tail[:-len(output_tail)]
      output_tail = output_tail[-len(output_tail):]
      if on_new_output: on_new_output(tail_to_remove)
      all_output.write(tail_to_remove)
      if not select.select([self.process.stdout], [], [], 10)[0]:
        raise MatlabConnectionError('timeout')
      new_output = self.process.stdout.read(65536)
      output_tail += new_output
    chunk_to_take, chunk_to_keep = output_tail.split(wait_for_str, 1)
    # chunk_to_take += wait_for_str # avoid display of the 'wait command'
    self.stdout_to_read = chunk_to_keep
    if on_new_output: on_new_output(chunk_to_take)
    all_output.write(chunk_to_take)
    all_output.seek(0)
    return all_output.read()

  def _sync_output(self, on_new_output=sys.stdout.write):
    """Read pipe until the ___MATLAB_PIPE_COMMAND_ENDED___ message appears
    Then searches foe the prompt >>
    """
    self.process.stdin.write('disp(\'%s\');\n' % self.command_end_string)
    ret = self._read_until(self.expected_output_end, on_new_output)
    # now read until the prompt comes in
    # self._read_until('>> ', on_new_output)
    
    return ret


if __name__ == '__main__':
  import unittest


  class TestMatlabPipe(unittest.TestCase):
    def setUp(self):
      self.matlab = MatlabPipe(matlab_process_path='guess', matlab_version='2011a')
      self.matlab.open()

    def tearDown(self):
      self.matlab.close()

    def test_eval(self):
      for i in xrange(100):
        ret = self.matlab.eval('disp \'hiush world%s\';' % ('b'*i))
        self.assertTrue('hiush world' in ret)

    def test_put(self):
      self.matlab.put({'A' : [1, 2, 3]})
      ret = self.matlab.eval('A')
      self.assertTrue('A =' in ret)

    def test_1_element(self):
      self.matlab.put({'X': 'string'})
      ret = self.matlab.get('X')
      self.assertEquals(ret, 'string')

    def test_get(self):
      self.matlab.eval('A = [1 2 3];')
      ret = self.matlab.get('A')
      self.assertEquals(ret[0], 1)
      self.assertEquals(ret[1], 2)
      self.assertEquals(ret[2], 3)

    def test_error(self):
      self.assertRaises(MatlabError,
                        self.matlab.eval,
                        'no_such_function')

  unittest.main()
