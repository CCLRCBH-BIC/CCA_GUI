
Updated on 11/5/2013


   - added 'clone_free' mode which detaches (frees) the variables of the 
       input mxArray while deep copying it into shared memory... this 
       should cut the maximum concurrent RAM usage during the deep copy when
       the input consists of many separate matrices (cell array, struct, etc...).
       Make sure there are no shared copies of the input before using!


    Suggested usage:


        data = load_some_big_data_stored_chunked_in_cell_array_or_struct;

        shmkey = 'hello_world';
        shmobj = shmobject(shmkey);
        [p t] = SharedMemory('clone_free',shmkey,data);

           do_something_with_workers (see example.m and below for more details)

        delete(shmobj);


--------------------------------------------------------------------------

This package is based on Joshua Dillon's 'SharedMatrix' file exchange
submission. Specifically, the SharedMatrix for windows code of 
Andrew Smith.

  Changes to that code include:

     1.) bug fixes for alignment (setting align_size in 
            SharedMemory.hpp was not working as intended)
           **16 byte alignment is now the default

     2.) addition of a 'force_free' mode that removes the 
            shared memory segment even if the reference count is >0

     3.) ability to call 'detach' with a 64-bit integer (which
            is actually a pointer)

     4.) 'detach' calls deepdetach on the input variable or pointer
            even if reference count is 0 (no longer errors out)

     5.) fixes for empty matrices and uninitialized cells in cell arrays

     6.) a few other changes to code flow to improve
            stability and help debugging


Two wrapper handle classes 'shmobject' and 'shmref' have been created 
to automate the process of calling 'clone'/'free' and 'attach'/'detach'.
These classes also prevent MATLAB from crashing when ctrl-c is used 
(or an error occurs) by insuring that 'detach' is always run before 
reference variables are cleaned up.

The shmref class relies on James Tursa's mxGetPropertyPtr file
exchange submission to operate. The following files from his
package have been renamed so that naming is more consistent:

   GetPropertyPtr.m    ->   shmGetPropertyPtr.m
   GetPropertyPtrx.c   ->   shmGetPropertyPtrx.c


example.m shows how shmobject/shmref are used.

The included binaries (.mexw64) were compiled with Visual Studio 2010 and Boost 1.53.

Tested with R2010a, R2010b, R2011a, and R2012a.
