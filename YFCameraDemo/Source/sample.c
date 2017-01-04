/*
 *  This code is released under the MIT License.
 *  Copyright (c) 2013 Nenad Markus
 */

#include <stdio.h>

// OpenCV 3.x required
// depending on your computer configuration (OpenCV install path), the following line might need modifications
#include <opencv2/highgui/highgui_c.h>

//
#include "picornt.h"

/*
	a portable time function
*/

#ifdef __GNUC__
#include <time.h>
float getticks()
{
	struct timespec ts;
	return ts.tv_sec + 1e-9f*ts.tv_nsec;
}
#else
#include <windows.h>
float getticks()
{
	static double freq = -1.0;
	LARGE_INTEGER lint;

	if(freq < 0.0)
	{
		if(!QueryPerformanceFrequency(&lint))
			return -1.0f;

		freq = lint.QuadPart;
	}

	if(!QueryPerformanceCounter(&lint))
		return -1.0f;

	return (float)( lint.QuadPart/freq );
}
#endif

/*
	
*/

void* cascade = 0;

int minsize;
int maxsize;

float angle;

float scalefactor;
float stridefactor;

float qthreshold;

int usepyr;
int noclustering;
int verbose;

void process_image(IplImage* frame, int draw)
{
	int i, j;
	float t;

	uint8_t* pixels;
	int nrows, ncols, ldim;

	#define MAXNDETECTIONS 2048
	int ndetections;
	float rcsq[4*MAXNDETECTIONS];

	static IplImage* gray = 0;
	static IplImage* pyr[5] = {0, 0, 0, 0, 0};

	/*
		...
	*/

	//
	if(!pyr[0])
	{
		//
		gray = cvCreateImage(cvSize(frame->width, frame->height), frame->depth, 1);

		//
		pyr[0] = gray;
		pyr[1] = cvCreateImage(cvSize(frame->width/2, frame->height/2), frame->depth, 1);
		pyr[2] = cvCreateImage(cvSize(frame->width/4, frame->height/4), frame->depth, 1);
		pyr[3] = cvCreateImage(cvSize(frame->width/8, frame->height/8), frame->depth, 1);
		pyr[4] = cvCreateImage(cvSize(frame->width/16, frame->height/16), frame->depth, 1);
	}

	// get grayscale image
    if(frame->nChannels == 3)
		cvCvtColor(frame, gray, CV_RGB2GRAY);
	else
		cvCopy(frame, gray, 0);

	// perform detection with the pico library
	t = getticks();

	if(usepyr)
	{
		int nd;

		//
		pyr[0] = gray;

		pixels = (uint8_t*)pyr[0]->imageData;
		nrows = pyr[0]->height;
		ncols = pyr[0]->width;
		ldim = pyr[0]->widthStep;

		ndetections = find_objects(rcsq, MAXNDETECTIONS, cascade, angle, pixels, nrows, ncols, ldim, scalefactor, stridefactor, MAX(16, minsize), MIN(128, maxsize));

		for(i=1; i<5; ++i)
		{
			cvResize(pyr[i-1], pyr[i], CV_INTER_LINEAR);

			pixels = (uint8_t*)pyr[i]->imageData;
			nrows = pyr[i]->height;
			ncols = pyr[i]->width;
			ldim = pyr[i]->widthStep;

			nd = find_objects(&rcsq[4*ndetections], MAXNDETECTIONS-ndetections, cascade, angle, pixels, nrows, ncols, ldim, scalefactor, stridefactor, MAX(64, minsize>>i), MIN(128, maxsize>>i));

			for(j=ndetections; j<ndetections+nd; ++j)
			{
				rcsq[4*j+0] = (1<<i)*rcsq[4*j+0];
				rcsq[4*j+1] = (1<<i)*rcsq[4*j+1];
				rcsq[4*j+2] = (1<<i)*rcsq[4*j+2];
			}

			ndetections = ndetections + nd;
		}
	}
	else
	{
		//
		pixels = (uint8_t*)gray->imageData;
		nrows = gray->height;
		ncols = gray->width;
		ldim = gray->widthStep;

		//
		ndetections = find_objects(rcsq, MAXNDETECTIONS, cascade, angle, pixels, nrows, ncols, ldim, scalefactor, stridefactor, minsize, MIN(nrows, ncols));
	}

	if(!noclustering)
		ndetections = cluster_detections(rcsq, ndetections);

	t = getticks() - t;

	// if the flag is set, draw each detection
	if(draw)
		for(i=0; i<ndetections; ++i)
			if(rcsq[4*i+3]>=qthreshold) // check the confidence threshold
				cvCircle(frame, cvPoint(rcsq[4*i+1], rcsq[4*i+0]), rcsq[4*i+2]/2, CV_RGB(255, 0, 0), 4, 8, 0); // we draw circles here since height-to-width ratio of the detected face regions is 1.0f

	// if the `verbose` flag is set, print the results to standard output
	if(verbose)
	{
		//
		for(i=0; i<ndetections; ++i)
			if(rcsq[4*i+3]>=qthreshold) // check the confidence threshold
				printf("%d %d %d %f\n", (int)rcsq[4*i+0], (int)rcsq[4*i+1], (int)rcsq[4*i+2], rcsq[4*i+3]);

		//
		//printf("# %f\n", 1000.0f*t); // use '#' to ignore this line when parsing the output of the program
	}
}

void initParams(void* c)
{
    cascade = c;

	// set default parameters
	minsize = 128;
	maxsize = 1024;

	angle = 0.0f;

	scalefactor = 1.1f;
	stridefactor = 0.1f;

	qthreshold = 5.0f;

	usepyr = 0;
	noclustering = 0;
	verbose = 0;

	
    printf("# cascade parameters:\n");
    printf("#	tsr = %f\n", ((float*)cascade)[0]);
    printf("#	tsc = %f\n", ((float*)cascade)[1]);
    printf("#	tdepth = %d\n", ((int*)cascade)[2]);
    printf("#	ntrees = %d\n", ((int*)cascade)[3]);
    printf("# detection parameters:\n");
    printf("#	minsize = %d\n", minsize);
    printf("#	maxsize = %d\n", maxsize);
    printf("#	scalefactor = %f\n", scalefactor);
    printf("#	stridefactor = %f\n", stridefactor);
    printf("#	qthreshold = %f\n", qthreshold);
    printf("#	usepyr = %d\n", usepyr);
}
