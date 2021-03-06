//  The MIT License (MIT)
//
//  Copyright (c) 2015 Microsoft
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//  UIColorExtensions.m
//

#import "UIColor+Extensions.h"

// UIColor (Extensions) implementation.
@implementation UIColor (Extensions)

/**
 * Creates and returns an opaque color object using the specified RGB value.
 *
 * @param rgb The red, green, blue value (e.g. 0x0193e8).
 * @return The color object. The color information represented by this object is in the device RGB colorspace.
 */
+ (instancetype)colorWithRGB:(UInt32)rgb
{
    return [UIColor colorWithRed:(CGFloat)(rgb >> 16 & 0xff) / (CGFloat)255.0
                           green:(CGFloat)(rgb >>  8 & 0xff) / (CGFloat)255.0
                            blue:(CGFloat)(rgb       & 0xff) / (CGFloat)255.0
                           alpha:(CGFloat)1.0];
}

/**
 * Creates and returns a color object using the specified RGBA value.
 *
 * @param rgba The red, green, blue value (e.g. 0x00000000 is black and 0xffffffff is white).
 * @return The color object. The color information represented by this object is in the device RGB colorspace.
 */
+ (instancetype)colorWithRGBA:(UInt32)rgba
{
    return [UIColor colorWithRed:(CGFloat)(rgba >> 24 & 0xff) / (CGFloat)255.0
                           green:(CGFloat)(rgba >> 16 & 0xff) / (CGFloat)255.0
                            blue:(CGFloat)(rgba >>  8 & 0xff) / (CGFloat)255.0
                           alpha:(CGFloat)(rgba       & 0xff) / (CGFloat)255.0];
}

/**
 * Creates and returns a opaque color object using the specified RGB component values.
 *
 * @param r The red component of the color object, specified as a value from 0 to 255.
 * @param g The green component of the color object, specified as a value from 0 to 255.
 * @param b The blue component of the color object, specified as a value from 0 to 255.
 * @return The color object. The color information represented by this object is in the device RGB colorspace.
 */
+ (instancetype)colorWithR:(UInt8)r g:(UInt8)g b:(UInt8)b
{
    return [UIColor colorWithRed:(CGFloat)r / (CGFloat)255.0
                           green:(CGFloat)g / (CGFloat)255.0
                            blue:(CGFloat)b / (CGFloat)255.0
                           alpha:(CGFloat)1.0];
}

/**
 * Creates and returns a color object using the specified RGBA component values.
 *
 * @param r The red component of the color object, specified as a value from 0 to 255.
 * @param g The green component of the color object, specified as a value from 0 to 255.
 * @param b The blue component of the color object, specified as a value from 0 to 255.
 * @param a The alpha component of the color object, specified as a value from 0 to 255.
 * @return The color object. The color information represented by this object is in the device RGB colorspace.
 */
+ (instancetype)colorWithR:(UInt8)r g:(UInt8)g b:(UInt8)b a:(UInt8)a
{
    return [UIColor colorWithRed:(CGFloat)r / (CGFloat)255.0
                           green:(CGFloat)g / (CGFloat)255.0
                            blue:(CGFloat)b / (CGFloat)255.0
                           alpha:(CGFloat)a / (CGFloat)255.0];
}

@end
