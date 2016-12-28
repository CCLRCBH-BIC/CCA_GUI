
function SharedMemory_compile(debug)
    
    arch = computer('arch');
    if debug
        mexopts = sprintf('mex -v -g -%s', arch);
    else
        mexopts = sprintf('mex -v -O -%s', arch);
    end
    
    % 64-bit platform
    if ~isempty(strfind(computer(),'64'))
        mexopts = sprintf('%s -largeArrayDims ', mexopts);
    end
    
    %include boost
    if ~isempty(strfind(computer(),'win')) || ...
            ~isempty(strfind(computer(),'WIN'))
        BOOST_dir = 'C:/boost_1_53_0_bin/';
    else
        % on Ubuntu: sudo aptitude install libboost-all-dev libboost-doc
        BOOST_dir = '/usr/include/';
    end
    
    if ~exist(fullfile(BOOST_dir,'boost','interprocess','windows_shared_memory.hpp'), 'file')
        error('%s\n%s\n', ...
            'Could not find the BOOST library. Please edit this file to include the BOOST location', ...
            '<BOOST_dir>\boost\interprocess\windows_shared_memory.hpp must exist');
    end
    
    mexopts = sprintf('%s -I''%s'' ', mexopts, BOOST_dir);
    
    eval([mexopts, 'SharedMemory.cpp']);
    
end

