% GetPropertyPtr returns the address of an object property as a UINT64 variable
%*************************************************************************************
% 
%  MATLAB (R) is a trademark of The Mathworks (R) Corporation
% 
%  Function:    GetPropertyPtr
%  Filename:    GetPropertyPtr.m
%  Programmer:  James Tursa
%  Version:     1.00
%  Date:        March 07, 2011
%  Copyright:   (c) 2011 by James Tursa, All Rights Reserved
% 
%   This code uses the BSD License:
% 
%   Redistribution and use in source and binary forms, with or without 
%   modification, are permitted provided that the following conditions are 
%   met:
% 
%      * Redistributions of source code must retain the above copyright 
%        notice, this list of conditions and the following disclaimer.
%      * Redistributions in binary form must reproduce the above copyright 
%        notice, this list of conditions and the following disclaimer in 
%        the documentation and/or other materials provided with the distribution
%       
%   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
%   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
%   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
%   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
%   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
%   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
%   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
%   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
%   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
%   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
%   POSSIBILITY OF SUCH DAMAGE.
%
%--------------------------------------------------------------------------
% 
%  GetPropertyPtr returns the address of the desired object property in a
%  UINT64 class variable. If there is an error in retrieving the property
%  then a 0 is returned. An error can result if the index is out of range
%  or the specified property does not exist or is not public. This function
%  will work with classdef variables or with structures or old-style user-
%  defined classes (treating the property name as a field name).
% 
%  The usage is as follows:
% 
%  Syntax
% 
%  D = GetPropertyPtr(obj)
%  D = GetPropertyPtr(obj,ix)
%  D = GetPropertyPtr(obj,ix,propname)
% 
%  where
%
%  obj      = Object
%  ix       = Index
%  propname = Property name
% 
%  Description
% 
%  GetPropertyPtr(obj) returns the address of obj.
%  GetPropertyPtr(obj,ix) returns the address of obj(ix).
%  GetPropertyPtr(obj,ix,propname) returns the address of obj(ix).propname.
%
%  GetPropertyPtr is a helper function for the mex function mxGetPropertyPtr
%  and generally is not intended to be called directly by the user, although
%  there is no technical reason why you can't do so. GetPropertyPtr itself
%  uses another C-mex helper function GetPropertyPtrx to get the address.
% 
%  Caution: GetPropertyPtrx uses unofficial behind-the-scenes hacking into the
%  mxArray structure of the input variables.  Thus, this is not guaranteed to
%  work for every version of MATLAB. Checks are made in an attempt to ensure
%  that the mxArray structures are as expected, but there is no guarantee that
%  this will work for all versions of MATLAB. If it doesn't work for you, please
%  contact the author. Also, if another process has access to the input(s) or
%  shared data copies of the inputs and changes them while GetPropertyPtr is
%  running then unpredictable results can occur, such as invalid results or
%  MATLAB crashing.
% 
%  Change Log:
%  2011/Mar/07 --> 1.00, Initial Release
% 
% ***************************************************************************/
 
function PropertyPtr = shmGetPropertyPtr(obj,ix,propname)
    
    if nargout > 1
        error('Too many outputs.');
    end
    
    try
        if( nargin == 0 )
            PropertyPtr = uint64(0);
        elseif( nargin == 1 )
            PropertyPtr = shmGetPropertyPtrx(obj);
        elseif( nargin == 2 )
            PropertyPtr = shmGetPropertyPtrx(obj(ix));
        elseif( nargin == 3 )
            PropertyPtr = shmGetPropertyPtrx(obj(ix).(propname));
        else
            error('Too many inputs.');
        end
    catch
        PropertyPtr = uint64(0);
    end
    
end
