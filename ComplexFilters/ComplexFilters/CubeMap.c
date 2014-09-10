//
//  CubeMap.c
//  ComplexFilters
//
//  Created by ZhangAo on 14-9-10.
//  Copyright (c) 2014年 zhangao. All rights reserved.
//
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

//void rgbToHSV(float rgb[3], float hsv[3]) {
//    unsigned char min, max, delta;
//    
//    if(rgb[0]<rgb[1])min=rgb[0]; else min=rgb[1];
//    if(rgb[2]<min)min=rgb[2];
//    
//    if(rgb[0]>rgb[1])max=rgb[0]; else max=rgb[1];
//    if(rgb[2]>max)max=rgb[2];
//    
//    hsv[2] = max;                // v, 0..255
//    
//    delta = max - min;                      // 0..255, < v
//    
//    if( max != 0 )
//        hsv[1] = (int)(delta)*255 / max;        // s, 0..255
//    else {
//        // r = g = b = 0        // s = 0, v is undefined
//        hsv[1] = 0;
//        hsv = 0;
//        return;
//    }
//    
//    if( rgb[0] == max )
//        hsv[0] = (rgb[1] - rgb[2])*60/delta;        // between yellow & magenta
//    else if( rgb[1] == max )
//        hsv[0] = 120 + (rgb[2] - rgb[0])*60/delta;    // between cyan & yellow
//    else
//        hsv[0] = 240 + (rgb[0] - rgb[1])*60/delta;    // between magenta & cyan
//    
//    if( hsv < 0 )
//        hsv += 360;
//}

// r,g,b values are from 0 to 1
// h = [0,360], s = [0,1], v = [0,1]
//		if s == 0, then h = -1 (undefined)

void rgbToHSV( float r, float g, float b, float *h, float *s, float *v )
{
    float min, max, delta;
    min = fmin(fmin(r, g), b );
    max = fmax(fmax(r, g), b );
    *v = max;				// v
    delta = max - min;
    if( max != 0 )
        *s = delta / max;		// s
    else {
        // r = g = b = 0		// s = 0, v is undefined
        *s = 0;
        *h = -1;
        return;
    }
    if( r == max )
        *h = ( g - b ) / delta;		// between yellow & magenta
    else if( g == max )
        *h = 2 + ( b - r ) / delta;	// between cyan & yellow
    else
        *h = 4 + ( r - g ) / delta;	// between magenta & cyan
    *h *= 60;				// degrees
    if( *h < 0 )
        *h += 360;
}


float *createCubeMap() {
    float minHueAngle = 290, maxHueAngle = 350;
    const unsigned int size = 64;
    float *cubeData = (float *)malloc (size * size * size * sizeof (float) * 4);
    float rgb[3], hsv[3], *c = cubeData;
    
    // Populate cube with a simple gradient going from 0 to 1
    for (int z = 0; z < size; z++){
        rgb[2] = ((double)z)/(size-1); // Blue value
        for (int y = 0; y < size; y++){
            rgb[1] = ((double)y)/(size-1); // Green value
            for (int x = 0; x < size; x ++){
                rgb[0] = ((double)x)/(size-1); // Red value
                // Convert RGB to HSV
                // You can find publicly available rgbToHSV functions on the Internet
                rgbToHSV(rgb[0],rgb[1],rgb[2],&hsv[0],&hsv[1],&hsv[2]);
                // Use the hue value to determine which to make transparent
                // The minimum and maximum hue angle depends on
                // the color you want to remove
                float alpha = (hsv[0] > minHueAngle && hsv[0] < maxHueAngle) ? 0.0f: 1.0f;
                // Calculate premultiplied alpha values for the cube
                c[0] = rgb[0] * alpha;
                c[1] = rgb[1] * alpha;
                c[2] = rgb[2] * alpha;
                c[3] = alpha;
                c += 4; // advance our pointer into memory for the next color value
            }
        }
    }
    return cubeData;
}