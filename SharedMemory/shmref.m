% SharedMemory reference wrapper class
%
%   This class creates the shared memory reference 
%   during construction -- SharedMemory('attach') -- 
%   and automatically releases it on destruction
%   -- SharedMemory('detach').
%
%   This function relies on the GetPropertyPtr mex
%   function of James Tursa in order to work.
classdef shmref < handle
    
    properties
        shmkey = 0;
        data = [];
    end
    
    methods
        function obj = shmref(shmkey)
            obj.data = SharedMemory('attach',shmkey);
            obj.shmkey = shmkey;
        end
        function delete(obj)
            % get the real pointer to obj.data first
            dptr = shmGetPropertyPtr(obj,1,'data');
            % then detach
            SharedMemory('detach',obj.shmkey,dptr);
        end
    end
    
end
