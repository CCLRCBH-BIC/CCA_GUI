% SharedMemory main wrapper class
%
%   This class creates the shared memory region during
%   construction -- SharedMemory('clone') -- and 
%   automatically frees it on destruction
%   -- SharedMemory('force_free').
classdef shmobject < handle
    
    properties
        shmkey = 0;
    end
    
    methods
        function obj = shmobject(shmkey,data)
            if nargin>1
                SharedMemory('clone',shmkey,data);
            end
            obj.shmkey = shmkey;
        end
        function delete(obj)
            refs_remaining = SharedMemory('force_free',obj.shmkey);
            if refs_remaining > 0
                fprintf(1,'shmobject:  non-zero ref count at deletion (%d)\n', ...
                    refs_remaining);
            end
        end
    end
    
end

