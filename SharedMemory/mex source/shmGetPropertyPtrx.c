/*************************************************************************************
 *
 * MATLAB (R) is a trademark of The Mathworks (R) Corporation
 *
 * Function:    GetPropertyPtrx
 * Filename:    GetPropertyPtrx.c
 * Programmer:  James Tursa
 * Version:     1.00
 * Date:        March 07, 2011
 * Copyright:   (c) 2011 by James Tursa, All Rights Reserved
 *
 *  This code uses the BSD License:
 *
 *  Redistribution and use in source and binary forms, with or without 
 *  modification, are permitted provided that the following conditions are 
 *  met:
 *
 *     * Redistributions of source code must retain the above copyright 
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright 
 *       notice, this list of conditions and the following disclaimer in 
 *       the documentation and/or other materials provided with the distribution
 *      
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 *  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
 *  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 *  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 *  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 *  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 *  POSSIBILITY OF SUCH DAMAGE.
 *
 *----------------------------------------------------------------------------
 *
 * Building:
 *
 * GetPropertyPtrx is typically self building. That is, the first time you call
 * it the GetPropertyPtrx.m file recognizes that the mex routine needs to be
 * compiled and then the compilation will happen automatically.
 *
 * The usage is as follows (arguments in brackets [ ] are optional):
 *
 * Syntax
 *
 * D = GetPropertyPtrx(A [,B [,C ...]])
 *
 *     A, B, C, ... = Any MATLAB variables, including class objects.
 *     D = Output array of MATLAB variable structure addresses, one for each input.
 *
 * Description
 *
 * GetPropertyPtrx returns the mxArray structure addresses of the inputs. If the
 * input is a temporary shared-data variable (e.g., the result of a structure,
 * object, or cell expression such as obj(ix).propname or cells{ix}) then the
 * GetPropertyPtrx function searches for the originating object and returns that
 * address instead of the address of the temporary variable. If a non-temporary
 * originating variable cannot be found, then the address of the input is simply
 * returned. The addresses are returned as elements of a UINT64 type variable.
 *
 * Caution: GetPropertyPtrx uses unofficial behind-the-scenes hacking into the
 * mxArray structure of the input variables.  Thus, this is not guaranteed to
 * work for every version of MATLAB. Checks are made in an attempt to ensure
 * that the mxArray structures are as expected, but there is no guarantee that
 * this will work for all versions of MATLAB. If it doesn't work for you, please
 * contact the author. Also, if another process has access to the input(s) or
 * shared data copies of the inputs and changes them while GetPropertyPtrx is
 * running then unpredictable results can occur, such as invalid results or
 * MATLAB crashing.
 *
 * Change Log:
 * 2011/Mar/07 --> 1.00, Initial Release
 *
 ****************************************************************************/

/* Includes ----------------------------------------------------------- */

#include "mex.h"

/* Macros ------------------------------------------------------------- */

#ifndef  MWSIZE_MAX
#define  MWSIZE_MAX
#define  mwIndex        int
#define  mwSignedIndex  int
#define  mwSize         int
#endif

#define TMW_NAME_LENGTH_MAX_ 64

#define INT64_TYPE long long

#define VariableType_Normal      0
#define VariableType_Persistent  1
#define VariableType_Global      2
#define VariableType_SubElement  3
#define VariableType_Temporary   4
#define VariableType_Unknown     5
#define VariableType_Property    6

/*-------------------------------------------------------------------------------
 * Partial mxArray structure used for determining if a variable is a temporary
 * shared data copy of another variable. If so, the CrossLink is used to track
 * down the address of the originating variable.
 *------------------------------------------------------------------------------- */

struct mxArray_Tag_Partial_Old {
	char name[TMW_NAME_LENGTH_MAX_];
	mxClassID ClassID;
	int VariableType;
	mxArray *CrossLink;
	size_t ndim;
};

struct mxArray_Tag_Partial_New {
	char *name;
	mxClassID ClassID;
	int VariableType;
	mxArray *CrossLink;
	size_t ndim;
};

/* Global ----------------------------------------------------------------------- */

int getisnew = 1;
int isnew;

/*------------------------------------------------------------------------------- */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	const mxArray *mx, *my, *mz;
	struct mxArray_Tag_Partial_Old *mp_old;
	struct mxArray_Tag_Partial_New *mp_new;
	int i, VariableType;
	INT64_TYPE *theintegerp;
	union {INT64_TYPE theinteger; mxArray *thepointer;} uip; /* Used for non-compliant code below */

/* First execution, figure out which mxArray struct version we need to use */

	if( getisnew ) {
		mx = mxCreateDoubleScalar(1.0);
		mp_new = (struct mxArray_Tag_Partial_New *) mx;
		isnew = (mp_new->ClassID == mxDOUBLE_CLASS) && (mp_new->CrossLink == NULL) && (mp_new->ndim == 2);
		if( !isnew ) {
			mp_old = (struct mxArray_Tag_Partial_Old *) mx;
			if( (mp_old->ClassID != mxDOUBLE_CLASS) || (mp_old->CrossLink != NULL) || (mp_old->ndim != 2) ) {
				mexErrMsgTxt("Unknown mxArray structure. Cannot perform operation. Contact author.");
			}
		}
		mxDestroyArray(mx);
		getisnew = 0;
	}

/* Fill up the pointer array, one pointer for each input */

	plhs[0] = mxCreateNumericMatrix( 1, nrhs, mxUINT64_CLASS, mxREAL );
	theintegerp = (INT64_TYPE *) mxGetData(plhs[0]);
	for( i=0; i<nrhs; i++ ) {
		my = (mxArray *) prhs[i];
		/* First get the CrossLink and VariableType values of the input */
		if( isnew ) {
			mp_new = (struct mxArray_Tag_Partial_New *) my;
			mx = mp_new->CrossLink;
			VariableType = mp_new->VariableType;
		} else {
			mp_old = (struct mxArray_Tag_Partial_Old *) my;
			mx = mp_old->CrossLink;
			VariableType = mp_old->VariableType;
		}
		/* If the variable is a temporary shared data copy of another variable */
		if( mx && VariableType == VariableType_Temporary ) {
			/* Loop through the CrossLink linked list until we get back to the input */
			while( mx != my ) {
				if( isnew ) {
					mp_new = (struct mxArray_Tag_Partial_New *) mx;
					VariableType = mp_new->VariableType;
				} else {
					mp_old = (struct mxArray_Tag_Partial_Old *) mx;
					VariableType = mp_old->VariableType;
				}
				/* Save the address */
				mz = mx;
				if( isnew ) {
					mx = mp_new->CrossLink;
				} else {
					mx = mp_old->CrossLink;
				}
			}
			/* The last variable prior to the input is the originating variable */
			my = mz;
		}
		/* Return that address of the originating variable */
		uip.theinteger = 0;
		uip.thepointer = my;
		theintegerp[i] = uip.theinteger; /* Need to use non-compliant union code to avoid compiler bug */
	}
}
