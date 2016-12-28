/*
 * SharedMemory.cpp
 *
 * This Matlab Mex program allows you to matlab variable between different
 * Matlab processes under Windows (e.g. for the parrellel toolbox).  It has four functions:
 *
 * 1) clone:
 *    Recursively place the contents of a matlab array into shared memory.  
 *    This is a "full" copy, so at this point there is a copy of the data in Matlab's memory and shared memory
 * 2) attach:
 *    "Reconstitute" the shared data into the appropriate Matlab object using
 *    shallow copying.  The process that attaches to the shared memory will make the memory 
 *    persistent until it is free'd by the attaching process or the attaching process ends.
 * 3) detach:
 *    Remove the shallow references and detach the shared memory from the
 *    Matlab data space.  Ensure this is done before the variable is cleared
 *    or else Matlab WILL crash.
 * 4) free:
 *    Mark the shared memory for destruction.  The shared memory will only be destroyed when all processes attached to it have called free.
 *
 *	  Notes:
 *    1) This is reliant on the BOOST interprocess library to compile
 *    2) Do not use pack after a variable is attached or Matlab WILL crash
 *    3) Do not call "clear mex" while there is data in the shared memory.  The handle to the shared 
 *       memory will be lost and the only way to free it will be to restart the system.
 *
 *
 * This code can be compiled from within Matlab or command-line, assuming the
 * system is appropriately setup.  To compile, invoke:
 *
 * For 32-bit machines:
 *     mex -O -v -I<BoostDir> SharedMemory.cpp
 * For 64-bit machines:
 *     mex -largeArrayDims -O -v -I<BoostDir> SharedMemory.cpp
 *
 * where <BoostDir> is the Boost directory, e.g. C:\Program Files\Boost\boost_1_45_0
 * The Boost library (or at least the InterProcess library) must be present for this to compile
 *
 *  Example usage:
 *
 * Create a crazy matlab array
 Cell = {eye(3), struct('a', 1, 'b', sparse(eye(3))), 'dummy'};										   %different data types
 X = struct('cat', [], 'happy', 'I am', 'guff', randn(2,3,4,5), 'mayhem', sparse(randn(3,2 > .5)));    %different data types
 X.cat = Cell;  %to check recursion
 
 % copy the contents of x into shared memory (x retains its copy)	 
 SharedMemory('clone','x_shared',X);

 % make a copy variable Y from the shared memory.  Y's data exists in the shared memory
 Y = SharedMemory('attach','x_shared');	       

 % detach Y making it safe to destroy (Y will retain its cell/structure structure however all numeric matrices will be empty)
 % this must be done before Y is cleared or Matlab will crash 
 SharedMemory('detach', 'x_shared', Y);	   

 %Free the shared memory.  It will no longer be possible to attach a variable to 'x_shared'
 SharedMemory('free','x_shared')            
 *
 */


#include "SharedMemory.hpp"

/* shared memory for windows - shared mem is destroyed when no threads are attached to it*/
using namespace boost::interprocess;

/* define the segment container with static linkage */
/* shared memory will be destroyed when the shared memory is removed from this 
(or this is destroyed).  Each calling process will have its own version of this variable */
static shared_mem_stack SegmentBuffer;


/* ------------------------------------------------------------------------- */
/* Matlab gateway function                                                   */
/*                                                                           */
/* ------------------------------------------------------------------------- */
void mexFunction( int nlhs,       mxArray *plhs[], 
                  int nrhs, const mxArray *prhs[]  )
{
	/* For inputs */
	const mxArray*		mxDirective;			/*  Directive {clone, attach, detach, free}   */
	const mxArray*		mxSegName;				/*  Name of the shared memory segment         */ 
	const mxArray*		mxInput;                /*  Input array (for clone)					  */


	/* For storing inputs */
	char directive[MAXDIRECTIVELEN+1];
	char segment_name[MAXDIRECTIVELEN+1];

	/* for working with shared memory ... */
	windows_shared_memory* pSegment;			/* pointer to the segment that interfaces the shared memory */
	mapped_region*  pRegion;					/* pointer to the memory map for the shared memory */
	int			segIndex;						/* which segment in the current process? */
	size_t		sm_size;						/* size required by the shared memory */

	/* for storing the mxArrays ... */
	header_t	hdr; memset(&hdr,0,sizeof(header_t));					
	data_t		dat; memset(&dat,0,sizeof(data_t));

	/* check min number of arguments */
	if (nrhs < 2 )
	{	mexErrMsgIdAndTxt("MATLAB:SharedMemory", "Minimum input arguments missing; must supply directive and key.");	}

	/* assign inputs */
	mxDirective = prhs[0];
	mxSegName = prhs[1];

	/* get directive */
	if ( mxGetString(mxDirective,directive,MAXDIRECTIVELEN+1)!=0 )
		mexErrMsgIdAndTxt("MATLAB:SharedMemory", "First input argument must be {'clone','attach', 'detach','free'}.");

	/* get segment name */
	if (mxGetString(mxSegName,segment_name,MAXDIRECTIVELEN+1)!=0 )
		mexErrMsgIdAndTxt("MATLAB:SharedMemory",
				"Second input argument must be a string less than %i characters", MAXDIRECTIVELEN);

	/* check outputs */
	if( nlhs > 2 )
	{	mexErrMsgIdAndTxt("MATLAB:SharedMemory", "Function returns only one or two values");	}

	/* Switch yard {clone, attach, detach, free} */
	if (!strcmpi(directive, "clone") || !strcmpi(directive, "clone_free")) 
	{
		/********************/
		/*	Clone case		*/
		/********************/
		
		/* check the inputs */
		if (( nrhs < 3 ) || ( mxIsEmpty(prhs[2])))
		{	mexErrMsgIdAndTxt("MATLAB:SharedMemory:clone", "Required third argument is missing (variable) or empty."); }

		/* check output */
		if (nlhs>2 || (!strcmpi(directive, "clone_free") && nlhs<1))
		{	mexErrMsgIdAndTxt("MATLAB:SharedMemory:clone", "Clone zero, one, or two output variables. Clone_free requires one or two."); }

		/* Assign */
		if (mxGetClassID(prhs[2]) == mxUINT64_CLASS)
			mxInput = (const mxArray*)(((unsigned __int64*)mxGetData(prhs[2]))[0]);
		else
			mxInput = prhs[2];

		/* scan input data */
		sm_size = deepscan(&hdr, &dat, mxInput, NULL);

		#ifdef DEBUG
		mexPrintf("clone: Debug: deepscan done.\n");
		#endif
			
		/* create the segment */
		try
		{	
			/* changed from 'create_only' to 'open_or_create' per user Guy Katz suggestion */
			pSegment = new windows_shared_memory(open_or_create, segment_name, read_write, sm_size);   
		}
		catch(interprocess_exception &ex)
		{	
			mexPrintf("%i: %s\n", ex.get_error_code(), ex.what());
			mexErrMsgIdAndTxt("MATLAB:SharedMemory:clone", "SharedMemory::Could not create the memory segment(does it already exist?)"); 
		}

		/* attach the segment to this dataspace */
		pRegion = new mapped_region(*pSegment, read_write);
        if (pRegion->get_address() == NULL) 
		{ 	mexErrMsgIdAndTxt("MATLAB:SharedMemory:clone", "SharedMemory::Unable to attach shared memory to data space."); }

		/* Successful, so add it to the shared memory stack so its preserved after this function exits */
		segIndex = SegmentBuffer.addSegmentToBuffer(pSegment, pRegion);

		/* copy data to the shared memory */
		size_t dsize = deepcopy(&hdr, &dat, (char*)pRegion->get_address(), NULL, strcmpi(directive, "clone_free") ? NULL : (mxArray*)mxInput);
		if (dsize != sm_size)
		{
			mexPrintf("SharedMemory:  clone deepcopy incorrect size (%I64d,%I64d)!\n", dsize, sm_size);
			mexErrMsgIdAndTxt("MATLAB:SharedMemory:clone", "Incorrect deepcopy size");
		}
			
		/* free temporary allocation */
		deepfree(&dat);

		#ifdef DEBUG
		mexPrintf("clone: Debug: shared memory at: 0x%016x\n", pRegion->get_address());
		#endif
			
		/* return its size */
		if (nlhs > 0)
			plhs[0] = mxCreateDoubleScalar((double)sm_size);

		/* return input pointer */
		if (nlhs > 1)
		{
			plhs[1] = mxCreateNumericMatrix(1,1,mxUINT64_CLASS,mxREAL);
			((unsigned __int64 *)mxGetData(plhs[1]))[0] = (unsigned __int64)mxInput;
		}

	}
	else if (!strcmpi(directive, "attach")) 
	{
		/********************/
		/*	Attach case		*/
		/********************/

		/* check output */
		if (nlhs<1 || nlhs>2)
		{	mexErrMsgIdAndTxt("MATLAB:SharedMemory:attach", "Attach requires one or two output variables."); }

		pRegion = NULL;

		/* Has this shared memory segment been mapped in this region? */
		segIndex = SegmentBuffer.findSegmentByName(segment_name);

		if (segIndex < 0)
		{
			/* It hasn't, so attach to the shared memory segment */
			bool found = true;
			try
			{	
				pSegment = new windows_shared_memory(open_only, segment_name, read_write);  
			}
			catch(interprocess_exception &ex)
			{	
				mexPrintf("%i: %s\n", ex.get_error_code(), ex.what());
				mexPrintf("MATLAB:SharedMemory:attach:  could not attach to the memory segment (does it exist?)\n");
				found = false;
			}

			if (found)
			{
				/* Map the whole shared memory in this process */
				pRegion = new mapped_region(*pSegment, read_write);

				/* Check the validity */
				if (NULL == pRegion->get_address())
				{
					mexPrintf("MATLAB:SharedMemory:attach:  unable to attach shared memory to data space.\n");
					pRegion = NULL;
				}
				else
					segIndex = SegmentBuffer.addSegmentToBuffer(pSegment, pRegion);
			}

		}
		else
		{
			/* It has, so retrieve the mapping */
			pSegment = SegmentBuffer.getSegmentByIndex(segIndex);
			pRegion = SegmentBuffer.getRegionByIndex(segIndex);
		}

		mxArray *mxOutput;
		if (pRegion)
		{
			/* Restore the segments */
			shallowrestore((char*)pRegion->get_address(), &mxOutput);

			/* Tell the segment buffer that a matlab variables is "attached" to it */
			SegmentBuffer.addReferenceByIndex(segIndex);
		}
		else
			mxOutput = mxCreateDoubleScalar(0.0);

		plhs[0] = mxOutput;

		if (nlhs>1)
		{
			plhs[1] = mxCreateNumericMatrix(1,1,mxUINT64_CLASS,mxREAL);
			((unsigned __int64 *)mxGetData(plhs[1]))[0] = (unsigned __int64)plhs[0];
		}

	}
	else if (!strcmpi(directive, "detach")) 
	{
		/********************/
		/*	Dettach case	*/
		/********************/

		/* check validity */
		if (( nrhs < 3 ) || mxIsEmpty(prhs[0]))
		{	mexErrMsgIdAndTxt("MATLAB:SharedMemory:detach", "Required third argument is missing (variable) or empty.");	}

		/* check output */
		if (nlhs>1)
		{	mexErrMsgIdAndTxt("MATLAB:SharedMemory:detach", "Detach requires one or no output variables."); }
		
		/* Assign */
		if (mxGetClassID(prhs[2]) == mxUINT64_CLASS)
			mxInput = (const mxArray*)(((unsigned __int64*)mxGetData(prhs[2]))[0]);
		else
			mxInput = prhs[2];
		
		/* Find the segment */
		segIndex = SegmentBuffer.findSegmentByName(segment_name);

		/* check the mapping exists */
		if (segIndex < 0)
			mexPrintf("MATLAB:SharedMemory:detach:  there is no shared segment with this name in this process.\n");
		else
		{
			if (SegmentBuffer.getRefCountByIndex(segIndex) < 1)
				mexPrintf("MATLAB:SharedMemory:detach:  there are no variables attached to the shared memory in this process.\n");
			else
				SegmentBuffer.removeReferenceByIndex(segIndex);
		}

		/* NULL all of the Matlab pointers */
		deepdetach((mxArray*)mxInput);			/* Abuse const */

		if (nlhs>0)
		{
			plhs[0] = mxCreateNumericMatrix(1,1,mxUINT64_CLASS,mxREAL);
			((unsigned __int64 *)mxGetData(plhs[0]))[0] = (unsigned __int64)mxInput;
		}

	}
	else if (!strcmpi(directive, "free")) 
	{
		/********************/
		/*	free case		*/
		/********************/

		/* check output */
		if (nlhs>1)
		{	mexErrMsgIdAndTxt("MATLAB:SharedMemory:free", "Free requires one or no output variables."); }

		/* Find the segment */
		segIndex = SegmentBuffer.findSegmentByName(segment_name);

		/* check the mapping exists */
		int ret = 0;
		if (segIndex < 0)
			mexPrintf("MATLAB:SharedMemory:free:  there are no shared segments with this name in this process.\n");
		else
		{
			if (SegmentBuffer.getRefCountByIndex(segIndex) > 0)
			{
				ret = SegmentBuffer.getRefCountByIndex(segIndex);
				mexPrintf("MATLAB:SharedMemory:free:  there are still variables attached to the shared memory in this process (%d).\n", ret);
			}
			else
				SegmentBuffer.removeSegmentByIndex(segIndex,false);
		}

		if (nlhs>0)
			plhs[0] = mxCreateDoubleScalar((double)ret);
				
	}
	else if (!strcmpi(directive, "force_free"))
	{
		/*********************/
		/*	forced free case */
		/*********************/

		/* check output */
		if (nlhs>1)
		{	mexErrMsgIdAndTxt("MATLAB:SharedMemory:force_free", "Force_free requires one or no output variables."); }

		segIndex = SegmentBuffer.findSegmentByName(segment_name);

		int ret = 0;
		if (segIndex >= 0)
		{
			ret = SegmentBuffer.getRefCountByIndex(segIndex);
			SegmentBuffer.removeSegmentByIndex(segIndex,true);
		}

		if (nlhs>0)
			plhs[0] = mxCreateDoubleScalar((double)ret);

	}
	else 
	{	mexErrMsgIdAndTxt("MATLAB:SharedMemory", "Unrecognized directive."); } /* unrecognised directive */

}




/* ------------------------------------------------------------------------- */
/* deepdetach                                                                */
/*                                                                           */
/* Remove shared memory references to input matrix (in-situ), recursively    */
/* if needed.                                                                */
/*                                                                           */
/* Arguments:                                                                */
/*    Input matrix to remove references.                                     */
/* Returns:                                                                  */
/*    Pointer to start of shared memory segment.                             */
/* ------------------------------------------------------------------------- */
void deepdetach(mxArray *mxInput) {
	
	/* uses side-effects! */
	mwSize dims[] = {0,0};
	mwSize nzmax  = 0;
	size_t elemsiz;
	size_t i,n;

	/*for structure */
	size_t nFields, j;

	/* restore matlab  memory */
	if ( mxInput==(mxArray*)NULL || mxIsEmpty(mxInput) ) 
	{	return;		} 
	else if ( mxIsStruct(mxInput) )
	{
		/* detach each field for each element */
		n = mxGetNumberOfElements(mxInput);
		nFields = mxGetNumberOfFields(mxInput);
		for ( i = 0; i < n; i++ ) 					/* element */
		{	for (j = 0; j < nFields; j++) 			/* field */
			{  deepdetach((mxArray*)(mxGetFieldByNumber(mxInput,i,j)));  }/* detach this one */
		}
	}
	else if ( mxIsCell(mxInput) ) 
	{
		/* detach each cell */
		n = mxGetNumberOfElements(mxInput);
		for ( i = 0; i < n; i++ ) 
		{	deepdetach((mxArray*)(mxGetCell(mxInput,i))); }/* detach this one */

	}
	else if ( mxIsNumeric(mxInput) || mxIsLogical(mxInput) || mxIsChar(mxInput))  /* a matrix containing data */
	{	

		/* In safe mode these entries were allocated so remove them properly */
		#ifdef SAFEMODE
		mxFree(mxGetData(mxInput));
		mxFree(mxGetImagData(mxInput));
		#endif

		/* handle sparse objects */
		if ( mxIsSparse(mxInput) ) 
		{	
			/* I don't seem to be able to give sparse arrays zero size so (nzmax must be 1) */
			dims[0] = dims[1] = 1; nzmax = 1;
			if (mxSetDimensions(mxInput,dims,2))
			{	mexErrMsgIdAndTxt("MATLAB:SharedMemory:Unknown", "detach: unable to resize the array.");	}

			/* In safe mode these entries were allocated so remove them properly */
			#ifdef SAFEMODE
			mxFree(mxGetIr(mxInput));
			mxFree(mxGetJc(mxInput));
			#endif

			/* allocate 1 element */
			elemsiz = mxGetElementSize(mxInput);
			mxSetData(mxInput,mxCalloc(nzmax,elemsiz));
			if ( mxIsComplex(mxInput) )
				mxSetImagData(mxInput,mxCalloc(nzmax,elemsiz));
			else
				mxSetImagData(mxInput,(void*)NULL);
			
			/* allocate 1 element */
			mxSetNzmax(mxInput,nzmax);
			mxSetIr(mxInput,(mwSize*)mxCalloc(nzmax,sizeof(mwIndex)));
			mxSetJc(mxInput,(mwSize*)mxCalloc(dims[1]+1,sizeof(mwIndex)));
		}
		else
		{
			/* Can have zero size, so nullify data storage containers */
			if (mxSetDimensions(mxInput,dims,2))
			{	mexErrMsgIdAndTxt("MATLAB:SharedMemory:Unknown", "detach: unable to resize the array.");	}

			/* Doesn't allocate or deallocate any space for the pr or pi arrays */
			mxSetData(mxInput, (void*)NULL);
			mxSetImagData(mxInput, (void*)NULL);
		}
	} 
	else 
	{	mexErrMsgIdAndTxt("MATLAB:SharedMemory:InvalidInput", "detach: unsupported type."); }
}



/* ------------------------------------------------------------------------- */
/* shallowrestore                                                            */
/*                                                                           */
/* Shallow copy matrix from shared memory into Matlab form.                  */
/*                                                                           */
/* Arguments:                                                                */
/*    shared memory segment.                                                 */
/*    pointer to an mxArray pointer.                                         */
/* Returns:                                                                  */
/*    size of shared memory segment.                                         */
/* ------------------------------------------------------------------------- */
size_t shallowrestore(char *shm, mxArray** p_mxInput) 
{	

	/* for working with shared memory ... */
	size_t i, shmsiz;
	mxArray *mxChild;   /* temporary pointer */

	/* for working with payload ... */
	header_t *hdr;
	mwSize   *pSize;             /* pointer to the array dimensions */
	void     *pr=NULL,*pi=NULL;  /* real and imaginary data pointers */
	mwIndex  *ir=NULL,*jc=NULL;  /* sparse matrix data indices */
	 

	/* for structures */
	int ret;				     
	size_t nFields;				 /* number of fields */
	size_t field_num;			 /* current field */
	size_t strBytes;			 /* Number of bytes in the string recording the field names */
	char ** pFieldStr;           /* Array to pass to Matlab with the field names pFields[0] is a poitner to the first field name, pFields[1] is the pointer to the second*/

	/* for testing ... */
	static double pBuffer[50];
	for (int i = 0; i < 50; i++)
	{	pBuffer[i] = i;			}

	/* retrieve the data */
	hdr = (header_t*)shm;

	/* the size pointer */
	pSize = (mwSize*)(shm+sizeof(header_t));

	/* skip over the stored sizes */
	shm += pad_to_align(sizeof(header_t)+sizeof(mwSize)*hdr->nDims);


	/* Structure case */
	if ( hdr->isStruct )
	{
		#ifdef DEBUG
		mexPrintf("shallowrestore: Debug: found structure %d x %d.\n", pSize[0], pSize[1]);
		#endif

		/* Pull out the field names, they follow the size*/
		ret = NumFieldsFromString(shm, &nFields, &strBytes);
		
		/* check the recovery */
		if ((ret) || (nFields != hdr->nFields))
			mexErrMsgIdAndTxt("MATLAB:SharedMemory:clone", "Structure fields have not been recovered properly");

		/* And convert to something matlab understands */
		pFieldStr = (char**)mxCalloc(nFields, sizeof(char*));
		PointCharArrayAtString(pFieldStr, shm, nFields);
		
		/* skip over the stored field string */
		shm += strBytes;

		/*create the matrix */
		*p_mxInput = mxCreateStructArray(hdr->nDims, pSize, hdr->nFields, (const char**)pFieldStr);
		mxFree(pFieldStr);  /* should be able to do this now... */

		/* Go through each element */
		for ( i = 0; i < hdr->nzmax; i++ ) 
		{	for (field_num = 0; field_num < hdr->nFields; field_num++)	/* each field */
			{
				#ifdef DEBUG
				mexPrintf("shallowrestore: Debug: working on %d field %d at 0x%016x.\n",i,field_num, *p_mxInput);
				#endif
				/* And fill it */
				shmsiz = shallowrestore(shm,&mxChild);					  /* restore the mxArray */
				mxSetFieldByNumber(*p_mxInput, i, field_num, mxChild);    /* and pop it in	   */
				shm += shmsiz;
			
				#ifdef DEBUG
				mexPrintf("shallowrestore: Debug: completed %d field %d.\n",i, field_num);
				#endif
			}
		}
	}
	else if ( hdr->isCell ) /* Cell case */ 
	{
		#ifdef DEBUG
		mexPrintf("shallowrestore: Debug: found cell %d x %d.\n",pSize[0], pSize[1]);
		#endif

		/* Create the array */
		*p_mxInput = mxCreateCellArray(hdr->nDims, pSize);
		for ( i = 0; i < hdr->nzmax; i++ ) {
			#ifdef DEBUG
			mexPrintf("shallowrestore: Debug: working on %d.\n",i);
			#endif
			/* And fill it */
			shmsiz = shallowrestore(shm, &mxChild);
			mxSetCell(*p_mxInput, i, mxChild);
			shm += shmsiz;
			#ifdef DEBUG
			mexPrintf("shallowrestore: Debug: completed %d at 0x%016x.\n",i,mxChild);
			#endif
		}
	} 
	else     /*base case*/
	{
		/* this is the address of the first data */ 
		pr = (void*)shm;
		shm += pad_to_align((hdr->nzmax)*(hdr->elemsiz));		/* takes us to the end of the real data */

		/* if complex get a pointer to the complex data */
		if ( hdr->isComplex ) {
			pi = (void*)shm;
			shm += pad_to_align((hdr->nzmax)*(hdr->elemsiz));	/* takes us to the end of the complex data */
		}

		if (hdr->nzmax == 0) // empty matrix
			pr = pi = NULL;
		
		/* if sparse get a list of the elements */
		if ( hdr->isSparse ) 
		{
			#ifdef DEBUG
			mexPrintf("shallowrestore: Debug: found non-cell, sparse 0x%016x.\n",*p_mxInput);
			#endif

			ir = (mwIndex*)shm;
			shm += pad_to_align((hdr->nzmax)*sizeof(mwIndex));
			if (hdr->nzmax == 0)
				ir = NULL;

			jc = (mwIndex*)shm;
			shm += pad_to_align((pSize[1]+1)*sizeof(mwIndex));
		
			/* FIX: need to create sparse logical differently */
			if ( hdr->classid==mxLOGICAL_CLASS )
			{	*p_mxInput = mxCreateSparseLogicalMatrix(0,0,0); }
			else
			{	*p_mxInput = mxCreateSparse(0,0,0,(hdr->isComplex)?mxCOMPLEX:mxREAL); }
			
			/* Free the memory it was created with */
			mxFree(mxGetIr(*p_mxInput));
			mxFree(mxGetJc(*p_mxInput));

			/* set the size */
			if (mxSetDimensions(*p_mxInput, pSize, hdr->nDims))
			{	mexErrMsgIdAndTxt("MATLAB:SharedMemory:Unknown", "attach: unable to resize the sparse array."); }

			/* set the pointers relating to sparse (set the real and imaginary data later)*/
			#ifndef SAFEMODE
		
			/* Hack  Method */
			((Internal_mxArray*)*p_mxInput)->data.number_array.reserved5    = ir;
			((Internal_mxArray*)*p_mxInput)->data.number_array.reserved6[0] = (size_t)jc;
			((Internal_mxArray*)*p_mxInput)->data.number_array.reserved6[1] = (size_t)(hdr->nzmax);

			#else
		
			/* Safe - but takes it out of global memory */
			mxSetIr(*p_mxInput, (mwIndex*)safeCopy(ir, (hdr->nzmax)*sizeof(mwIndex)));
			mxSetJc(*p_mxInput, (mwIndex*)safeCopy(jc, (pSize[1]+1)*sizeof(mwIndex)));  						
			
			#endif
			mxSetNzmax(*p_mxInput,hdr->nzmax);

		} else {

			/*  rebuild constitute the array  */
			#ifdef DEBUG
			mexPrintf("shallowrestore: Debug: found non-cell, non-sparse.\n");
			#endif

			/*  create an empty array */
			*p_mxInput = mxCreateNumericMatrix(0,0,hdr->classid,(hdr->isComplex)?mxCOMPLEX:mxREAL);

			/* set the size */
			if (mxSetDimensions(*p_mxInput, pSize, hdr->nDims))
			{	mexErrMsgIdAndTxt("MATLAB:SharedMemory:Unknown", "attach: unable to resize the array."); }
		}

		
		/* Free the memory it was created with (shouldn't be necessary) */
		mxFree(mxGetPr(*p_mxInput));
		mxFree(mxGetPi(*p_mxInput));

		/* set the real and imaginary data */
		#ifndef SAFEMODE
		
		/* Hack  Method */
		/* ((Internal_mxArray*)(*p_mxInput))->data.number_array.pdata = pBuffer;  / * works assuming the size is <= 50 * / */
		((Internal_mxArray*)(*p_mxInput))->data.number_array.pdata = pr;		 /* Hack */											 
		if ( hdr->isComplex ) 
		{	((Internal_mxArray*)(*p_mxInput))->data.number_array.pimag_data = pi;   }
		
		#else
		
		/* Safe - but takes it out of global memory */
		mxSetData(*p_mxInput, safeCopy(pr, hdr->nzmax*hdr->elemsiz));
		if ( hdr->isComplex )
		{	mxSetImagData(*p_mxInput, safeCopy(pi, hdr->nzmax*hdr->elemsiz));  }						
		#endif

	}

	if ((((unsigned __int64)hdr->shmsiz)%align_size)|(((unsigned __int64)shm)%align_size))
	{		
		mexPrintf("Bad alignment - shallowrestore (%I64d %I64d)\n", hdr->shmsiz, shm);
		mexErrMsgIdAndTxt("MATLAB:SharedMemory:Unknown", "Bad alignment - shallowrestore."); 
	}

	return hdr->shmsiz;
}



/* ------------------------------------------------------------------------- */
/* deepscan                                                                  */
/*                                                                           */
/* Recursively descend through Matlab matrix to assess how much space its    */
/* serialization will require.                                               */
/*                                                                           */
/* Arguments:                                                                */
/*    header to populate.                                                    */
/*    data container to populate.                                            */
/*    mxArray to analyze.                                                    */
/* Returns:                                                                  */
/*    size that shared memory segment will need to be.                       */
/* ------------------------------------------------------------------------- */
size_t deepscan(header_t *hdr, data_t *dat, const mxArray* mxInput, header_t*  par_hdr) 
{	
	/* counter */
	size_t i;

	/* for structures */	
	size_t field_num, count;
	size_t strBytes;

	/* initialize data info; _possibly_ update these later */
	dat->pSize     = ( mwSize* )NULL;
	dat->pr        = (    void*)NULL;
	dat->pi        = (    void*)NULL;
	dat->ir        = ( mwIndex*)NULL;
	dat->jc        = ( mwIndex*)NULL;
	dat->child_dat = (  data_t*)NULL;
	dat->child_hdr = (header_t*)NULL;
	dat->field_str = (    char*)NULL;
	hdr->par_hdr_off = 0;               /*don't record it here */

	if ( mxInput==(const mxArray*)NULL ) {
		/* initialize header info */
		hdr->isCell     = 0;
		hdr->isSparse   = 0;
		hdr->isComplex  = 0;
		hdr->isStruct   = 0; 
		hdr->classid    = mxDOUBLE_CLASS;
		hdr->nDims      = 2;
		hdr->elemsiz    = 8;
		hdr->nzmax      = 0;
		hdr->nFields    = 0; 
		hdr->shmsiz     = pad_to_align(sizeof(header_t) + hdr->nDims * sizeof(mwSize));

		return hdr->shmsiz;
	}

	/* initialize header info */
	hdr->isCell    = mxIsCell(mxInput);
	hdr->isSparse  = mxIsSparse(mxInput);
	hdr->isComplex = mxIsComplex(mxInput);
	hdr->isStruct  = mxIsStruct(mxInput);
	hdr->classid   = mxGetClassID(mxInput);
	hdr->nDims     = mxGetNumberOfDimensions(mxInput); 
	hdr->elemsiz   = mxGetElementSize(mxInput);
	hdr->nzmax     = mxGetNumberOfElements(mxInput);	/* update this later on sparse*/
	hdr->nFields   = 0;									/* update this later */
	hdr->shmsiz    = 0;					/* update this later */

	/* copy the size */
	dat->pSize     = (mwSize*)mxGetDimensions(mxInput);	/* some abuse of const for now, fix on deep copy*/

	/* Add space for the dimensions */
	hdr->shmsiz += pad_to_align(sizeof(header_t) + hdr->nDims * sizeof(mwSize));

	/* Structure case */
	if (hdr->isStruct)
	{
		#ifdef DEBUG
		mexPrintf("deepscan: Debug: found structure.\n");
		#endif

		/* How many fields to work with? */
		hdr->nFields = mxGetNumberOfFields(mxInput);

		/* Find the size required to store the field names */
		strBytes = FieldNamesSize(mxInput);     /* always a multiple of alignment size */
		hdr->shmsiz += strBytes;			    /* Add space for the field string */
		
		/* use mxCalloc so mem is freed on error via garbage collection */
		dat->child_hdr = (header_t*)mxCalloc(hdr->nzmax * hdr->nFields * (sizeof(header_t) + 
			sizeof(data_t)) + strBytes, 1); /* extra space for the field string */
		dat->child_dat = (data_t*)&dat->child_hdr[hdr->nFields * hdr->nzmax];
		dat->field_str = (char*)&dat->child_dat[hdr->nFields * hdr->nzmax];

		/* make a record of the field names */
		CopyFieldNames(mxInput, dat->field_str);

		/* go through each recursively */
		count = 0;
		for (i = 0; i < hdr->nzmax; i++ )					/* each element */
		{   for (field_num = 0; field_num < hdr->nFields; field_num++)	/* each field */
			{
				/* call recursivley */
				hdr->shmsiz +=	deepscan(&(dat->child_hdr[count]), 
			                    &(dat->child_dat[count]), mxGetFieldByNumber(mxInput,i,field_num), hdr);

				count++; /* progress */
				#ifdef DEBUG
				mexPrintf("deepscan: Debug: finished element %d field %d.\n",i,field_num);
				#endif
			}
		}
	}
	else if ( hdr->isCell ) /* Cell case */
	{
		#ifdef DEBUG
		mexPrintf("deepscan: Debug: found cell.\n");
		#endif
		
		/* use mxCalloc so mem is freed on error via garbage collection */
		dat->child_hdr = (header_t*)mxCalloc(hdr->nzmax,sizeof(header_t) + sizeof(data_t));
		dat->child_dat = (data_t*)&dat->child_hdr[hdr->nzmax];

		/* go through each recursively */
		for ( i=0;i<hdr->nzmax;i++ ) {
			hdr->shmsiz +=	deepscan(&(dat->child_hdr[i]), &(dat->child_dat[i]), mxGetCell(mxInput,i), hdr);
			#ifdef DEBUG
			mexPrintf("deepscan: Debug: finished %d.\n",i);
			#endif
		}
		
		/* if its a cell it has to have at least one mom-empty element */
		if ( hdr->shmsiz==(1+hdr->nzmax)*pad_to_align(sizeof(header_t)) )
			mexErrMsgIdAndTxt("MATLAB:SharedMemory:clone",
					"Required third argument (variable) must contain at "
					"least one non-empty item (at all levels).");
	}
	else if ( mxIsNumeric(mxInput) || mxIsLogical(mxInput) || mxIsChar(mxInput))  /* a matrix containing data *//* base case */ 
	{
		dat->pr = mxGetData(mxInput);
		dat->pi = mxGetImagData(mxInput);
		
		/*is it sparse? */
		if ( hdr->isSparse ) {
			/* len(pr)=nzmax, len(ir)=nzmax, len(jc)=colc+1 */
			hdr->nzmax = mxGetNzmax(mxInput);
			dat->ir = mxGetIr(mxInput);
			dat->jc = mxGetJc(mxInput);
			hdr->shmsiz += pad_to_align(sizeof(mwIndex)*(hdr->nzmax));      /* ensure both pointers are aligned individually */
			hdr->shmsiz += pad_to_align(sizeof(mwIndex)*(dat->pSize[1]+1));
		} 
		
		/* ensure both pointers are aligned individually */
		hdr->shmsiz += pad_to_align(hdr->elemsiz*hdr->nzmax);
		if (hdr->isComplex)
		{	hdr->shmsiz += pad_to_align(hdr->elemsiz*hdr->nzmax);		}
	}
	else
	{	
		mexPrintf("Unknown class found: %s\n", mxGetClassName(mxInput));
		mexErrMsgIdAndTxt("MATLAB:SharedMemory:InvalidInput", "clone: unsupported type."); 
	}

	if (((unsigned __int64)hdr->shmsiz)%align_size)
	{		
		mexPrintf("Bad alignment - deepscan (%I64d - %d %d)\n", hdr->shmsiz, hdr->isStruct, hdr->isCell);
		mexErrMsgIdAndTxt("MATLAB:SharedMemory:Unknown", "Bad alignment - deepscan."); 
	}

	return hdr->shmsiz;
}


/* ------------------------------------------------------------------------- */
/* deepcopy                                                                  */
/*                                                                           */
/* Descend through header and data structure and copy relevent data to       */
/* shared memory.                                                            */
/*                                                                           */
/* Arguments:                                                                */
/*    header to serialize.                                                   */
/*    data container of pointers to data to serialize.                       */
/*    pointer to shared memory segment.                                      */
/* Returns:                                                                  */
/*    void                                                                   */
/* ------------------------------------------------------------------------- */
size_t deepcopy(header_t *hdr, data_t *dat, char *shm, header_t*  par_hdr, mxArray *mxInput) {
	
	header_t *cpy_hdr;		/* the header in its copied location */ 
	size_t i,j,count,elemsiz,n,offset=0;
	mwSize *pSize;			/* points to the size data */
	mwSize dims[] = {0,0}, nzmax = 0;

	/* for structures */	
	size_t nFields, strBytes;
	int ret;

	/* load up the shared memory */
	char *shm_saved = shm;

	/* copy the header */
	n = sizeof(header_t);
	memcpy(shm,hdr,n);

	/* copy the dimensions */
	cpy_hdr = (header_t*)shm;
	pSize = (mwSize*)&shm[n];
	for (i = 0; i < cpy_hdr->nDims; i++)
	{
		if (dat->pSize)
			pSize[i] = dat->pSize[i];
		else
			pSize[i] = 0;
	}
	offset += pad_to_align(n + cpy_hdr->nDims * sizeof(mwSize));

	/* assign the parent header  */
	cpy_hdr->par_hdr_off = (NULL == par_hdr) ? 0 : (int)(par_hdr - cpy_hdr);
	shm += offset;         

	/* Structure case */
	if (hdr->isStruct)
	{
		#ifdef DEBUG
		mexPrintf("deepcopy: Debug: found structure.\n");
		#endif

		/* place the field names next in shared memory */
		ret = NumFieldsFromString(dat->field_str, &nFields, &strBytes);

		/* check the recovery */
		if ((ret) || (nFields != hdr->nFields))
			mexErrMsgIdAndTxt("MATLAB:SharedMemory:clone", "Structure fields have not been recovered properly");

		/* copy the field string */
		for (i = 0; i < strBytes; i++)
			shm[i] = dat->field_str[i];
		shm += strBytes;
		
		/* copy the children recursively */
		count = 0;
		for(i=0; i < hdr->nzmax; i++) 
		{
			for (j=0; j<hdr->nFields; ++j, ++count)
			{
				deepcopy(&(dat->child_hdr[count]),&(dat->child_dat[count]),shm,cpy_hdr,
					mxInput?(mxArray*)mxGetFieldByNumber(mxInput,i,j):NULL);
				shm += (dat->child_hdr[count]).shmsiz;
			}
		}
	}
	else if ( hdr->isCell ) /* Cell case */ 
	{
		/* recurse for each cell element */
		#ifdef DEBUG
		mexPrintf("deepcopy: Debug: found cell.\n");
		#endif

		/* recurse through each cell */
		for(i=0;i<hdr->nzmax;i++) 
		{
			deepcopy(&(dat->child_hdr[i]),&(dat->child_dat[i]),shm,cpy_hdr,
				mxInput?(mxArray*)mxGetCell(mxInput,i):NULL);
			shm+=(dat->child_hdr[i]).shmsiz;
		}
	} 
	else /* base case */ 
	{	
		/* copy real data */
		n = (hdr->nzmax)*(hdr->elemsiz);
		memcpy(shm,dat->pr,n);
		shm += pad_to_align(n);

		/* copy complex data as well */
		if ( hdr->isComplex ) {
			n = (hdr->nzmax)*(hdr->elemsiz);
			memcpy(shm,dat->pi,n);
			shm += pad_to_align(n);
		}
		
		/* and the indices of the sparse data as well */
		if ( hdr->isSparse ) 
		{
			n = hdr->nzmax*sizeof(mwIndex);
			memcpy(shm,dat->ir,n);
			shm += pad_to_align(n);

			n = (pSize[1]+1)*sizeof(mwIndex);
			memcpy(shm,dat->jc,n);
			shm += pad_to_align(n);

			if (mxInput)
			{
				mxFree(mxGetData(mxInput));
				mxFree(mxGetImagData(mxInput));
				mxFree(mxGetIr(mxInput));
				mxFree(mxGetJc(mxInput));
				/* I don't seem to be able to give sparse arrays zero size so (nzmax must be 1) */
				dims[0] = dims[1] = 1; nzmax = 1;
				if (mxSetDimensions(mxInput,dims,2))
					mexErrMsgIdAndTxt("MATLAB:SharedMemory:Unknown", "deepcopy: unable to resize the array (sparse).");
				elemsiz = mxGetElementSize(mxInput);
				mxSetData(mxInput,mxCalloc(nzmax,elemsiz));
				if ( hdr->isComplex )
					mxSetImagData(mxInput,mxCalloc(nzmax,elemsiz));
				else
					mxSetImagData(mxInput,(void*)NULL);
				mxSetNzmax(mxInput,nzmax);
				mxSetIr(mxInput,(mwSize*)mxCalloc(nzmax,sizeof(mwIndex)));
				mxSetJc(mxInput,(mwSize*)mxCalloc(dims[1]+1,sizeof(mwIndex)));
			}
		}
		else if (mxInput)
		{
			mxFree(mxGetData(mxInput));
			mxFree(mxGetImagData(mxInput));
			if (mxSetDimensions(mxInput,dims,2))
				mexErrMsgIdAndTxt("MATLAB:SharedMemory:Unknown", "deepcopy: unable to resize the array (dense).");
			mxSetData(mxInput,(void*)NULL);
			mxSetImagData(mxInput,(void*)NULL);
		}
	}

	return ((unsigned __int64)shm)-((unsigned __int64)shm_saved);
}


/* ------------------------------------------------------------------------- */
/* deepfree                                                                  */
/*                                                                           */
/* Descend through header and data structure and free the memory.            */
/*                                                                           */
/* Arguments:                                                                */
/*    data container                                                         */
/* Returns:                                                                  */
/*    void                                                                   */
/* ------------------------------------------------------------------------- */
void deepfree(data_t *dat) {
	
	/* recurse to the bottom */
	if ( dat->child_dat ) deepfree(dat->child_dat);

	/* free on the way back up */
	mxFree(dat->child_hdr);
	dat->child_hdr = (header_t*)NULL;
	dat->child_dat = (  data_t*)NULL;
	dat->field_str = (char *)NULL;
}


/* Function to find the number of bytes required to store all of the */
/* field names of a structure									     */
int FieldNamesSize(const mxArray * mxStruct)
{
	const char*  pFieldName;
	int nFields;
	int i,j;			/* counters */
	int Bytes = 0;

	/* How many fields? */
	nFields = mxGetNumberOfFields(mxStruct);

	/* Go through them */
	for (i = 0; i < nFields; i++)
	{
		/* This field */
		pFieldName = mxGetFieldNameByNumber(mxStruct,i);
		j = 0;
		while (pFieldName[j])
		{	j++; }
		j++;		/* for the null termination */

		if (i == (nFields - 1))
			j++;	/* add this at the end for an end of string sequence since we use 0 elsewhere (term_char). */
		            

		/* Pad it out to 8 bytes */
		j = pad_to_align(j);

		/* keep the running tally */
		Bytes += j;

	}

	/* Add an extra alignment size to store the length of the string (in Bytes) */
	Bytes += align_size;

	return Bytes;

}

/* Function to copy all of the field names to a character array    */
/* Use FieldNamesSize() to allocate the required size of the array */
/* returns the number of bytes used in pList					   */
int CopyFieldNames(const mxArray * mxStruct, char* pList)
{
	const char*  pFieldName;    /* name of the field to add to the list */
	int nFields;				/* the number of fields */
	int i,j;					/* counters */
	int Bytes = 0;				/* number of bytes copied */

	/* How many fields? */
	nFields = mxGetNumberOfFields(mxStruct);

	/* Go through them */
	for (i = 0; i < nFields; i++)
	{
		/* This field */
		pFieldName = mxGetFieldNameByNumber(mxStruct,i);
		j = 0;
		while (pFieldName[j])
		{	pList[Bytes++]=pFieldName[j++];   }
		pList[Bytes++] = 0; /* add the null termination */

		/* if this is last entry indicate the end of the string */
		if (i == (nFields - 1))
		{	
			pList[Bytes++] = term_char;
			pList[Bytes++] = 0;  /* another null termination just to be safe */
		}

		/* Pad it out to 8 bytes */
		while (Bytes % align_size)
		{	pList[Bytes++] = 0;   }
	}

	/* Add an extra alignment size to store the length of the string (in Bytes) */
	*(unsigned int*)&pList[Bytes] = (unsigned int)(Bytes + align_size);
	Bytes += align_size;

	return Bytes;

}

/*Function to take point a each element of the char** array at a list of names contained in string */
/*ppCharArray must be allocated to length num_names */
/*names are seperated by null termination characters */
/*each name must start on an aligned address (see CopyFieldNames()) */
/*e.g. pCharArray[0] = &name_1, pCharArray[1] = &name_2 ...         */
/*returns 0 if successful */
int PointCharArrayAtString(char ** pCharArray, char* pString, int nFields)
{ 
	int i = 0;					    /* the index in pString we are up to */
	int field_num = 0;			    /* the field we are up to */

	/* and recover them */
	while (field_num < nFields)
	{
		/* scan past null termination chars */
		while (!pString[i])
			i++;

		/* Check the address is aligned (assume every forth bytes is aligned) */
		if (i % align_size)
			return -1;

		/* grab the address */
		pCharArray[field_num] = &pString[i];
		field_num++;

		/* continue until a null termination char */
		while (pString[i])
			i++;

	}
	return 0;
}

/* This function finds the number of fields contained within in a string */
/* the string is terminated by term_char, a character that can't be in a field name */
/* returns the number of field names found */
/* returns -1 if unaligned field names are found */
int NumFieldsFromString(const char* pString, size_t *pFields, size_t* pBytes)
{
	unsigned int stored_length;		/* the recorded length of the string */
	bool term_found = false;		/* has the termination character been found? */
	int i = 0;						/* counter */

	pFields[0] = 0;					/* the number of fields in the string */
	pBytes[0] = 0;


	/* and recover them */
	while (!term_found)
	{
		/* scan past null termination chars */
		while (!pString[i])
		{	i++;		 }

		/* is this the special termination character? */
		term_found = pString[i] == term_char;

		if (!term_found)
		{
			/* Check the address is aligned (assume every forth bytes is aligned) */
			if (i % align_size)
			{	return -1;    }

			/* a new field */
			pFields[0]++;

			/* continue until a null termination char */
			while (pString[i] && (pString[i] != term_char))
			{	i++;	}

			/* check there wasn't the terminal character immediately after the field */
			if (pString[i] == term_char)
			{	return -2;		}

		}
	}
	pBytes[0] = i;

	/* return the aligned size */
	pBytes[0] = pad_to_align(pBytes[0]);

	/* Check what's recovered matches the stored length */
	stored_length = *(unsigned int*)&pString[pBytes[0]] ;	  /* the recorded length of the string */
	pBytes[0] += align_size;								  /* add the extra space for the record */

	/* Check on it */
	if (stored_length != pBytes[0])
		return -3;

	return 0;

}

/* Function to find the bytes in the string starting from the end of the string (i.e. the last element is pString[-1])*/
/* returns < 0 on error */
int BytesFromStringEnd(const char* pString, size_t* pBytes)
{
	
	int offset = align_size;		  /* start from the end of the string */
	pBytes[0] = 0;					  /* default */

	/* Grab it directly from the string */
	pBytes[0] = (size_t)(*(unsigned int*)&pString[-offset]);

	/* scan for the termination character */
	while ((offset < 2*align_size) && (pString[-offset] != term_char))
	{ offset++;}

	if (offset == align_size)
	{	return -1;				}/* failure to find the control character */
	else
	{	return 0;				}/* happy */	 
	
}

/*
 * Possibly useful information/related work:
 *
 * http://www.mathworks.com/matlabcentral/fileexchange/24576
 * http://www.mathworks.in/matlabcentral/newsreader/view_thread/254813
 * http://www.mathworks.com/matlabcentral/newsreader/view_thread/247881#639280
 * 
 * http://groups.google.com/group/comp.soft-sys.matlab/browse_thread/thread/c241d8821fb90275/47189d498d1f45b8?lnk=st&q=&rnum=1&hl=en#47189d498d1f45b8
 * http://www.mk.tu-berlin.de/Members/Benjamin/mex_sharedArrays
 */
