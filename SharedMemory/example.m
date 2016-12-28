%
%  Example usage of SharedMemory and the wrapper classes 'shmobject' and 'shmref'.
%
%  Parameters:
%     msize   -> size of test matrix for calculations
%     niters  -> number of calculation iterations
%     uparfor -> 0 = use regular loop  or  1 = use parfor() loop
%     mdelete -> 1 = explicity call delete on shmobject/shmref objects  0 = don't
%
%   ** If you set mdelete=0 the objects will be cleaned up correctly, but
%      the order of destruction is not guaranteed. Therefore, the shmobject
%      destructor might be called before all of the shmref object destructors
%      are called. Since shmobject uses 'force_free' the shared memory segment
%      will be removed even if the reference count is not zero, but a warning
%      message about non-zero ref count will be displayed. Likewise, the
%      'detach' code that shmref calls will still null out the pointers of the
%      variable even if the shared memory segment no longer exists, but it
%      will also print out a warning message about no existing shared memory
%      segment. To avoid those warning messages explicity delete the objects
%      in the correct order.  **
%
function val = example(msize,niters,uparfor,mdelete)
    
    [~,sys] = memory;
    fprintf(1,'Physical Memory Available: %d\n', sys.PhysicalMemory.Available);
    
    % create a random matrix
    X = rand(msize,msize);
    
    tic;

    % put it in shared memory
    %   first need to generate a key to identify it
    shmkey = sprintf('shmtest_%04d_X',randi(9999,1,1));
    shmobj = shmobject(shmkey,X); % create wrapper object
    
    % clear X since it is now in shared memory
    clear X;
    
    q = zeros(1,niters);
    
    if uparfor

        parfor i=1:niters
            % create reference 'attach'
            robj = shmref(shmkey);
            % do calculations. X is really robj.data
            q(i) = sum(sum(robj.data*robj.data',1),2);
            % 'detach' is called automatically by the 
            % robj destructor. We can manually call
            % it or let matlab's memory management do it
            if mdelete
                delete(robj);
            end
        end
        
    else
      
        for i=1:niters
            % create reference 'attach'
            robj = shmref(shmkey);
            % do calculations. X is really robj.data
            q(i) = sum(sum(robj.data*robj.data',1),2);
            % 'detach' is called automatically by the 
            % robj destructor. We can manually call
            % it or let matlab's memory management do it
            if mdelete
                delete(robj);
            end
        end
        
    end
    
    val = sum(q);
    
    % 'free' is called automatically by the
    % shmobj destructor. We can manually call
    % it or let matlab's memory management do it
    if mdelete
        delete(shmobj);
    end
    
    toc;
    
    [~,sys] = memory;
    fprintf(1,'Physical Memory Available: %d\n', sys.PhysicalMemory.Available);
    
end
