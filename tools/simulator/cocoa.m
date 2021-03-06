// 
// Copyright (C) 2011-2014 Jeff Bush
// 
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
// 
 

#import <Cocoa/Cocoa.h>
#include "core.h"
#include "device.h"

//
// Code to display live framebuffer contents in a window
//

@interface FrameBufferView : NSView
{
	CGDataProviderRef mFbBitsProviderRef;
	int mWidth;
	int mHeight;
	Core *mCore;
}

- (void) dealloc;
- (void) executeCode;
- (void) setCore: (Core*) core;
- (void) updateFb;
- (void) keyDown:(NSEvent *) event;
- (void) keyUp:(NSEvent *) event;
- (BOOL) acceptsFirstResponser;

@end

@implementation FrameBufferView

- (id) initWithFrame: (NSRect) frameRect
{
	self = [super initWithFrame: frameRect];

	mWidth = frameRect.size.width;
	mHeight = frameRect.size.height;

	return self;
}

- (void) setFb:(void*) baseAddress
{
	mFbBitsProviderRef = CGDataProviderCreateWithData(NULL, baseAddress, 
		mWidth * 4 * mHeight, NULL);
}

- (void) dealloc
{
	if (mFbBitsProviderRef)
		CGDataProviderRelease(mFbBitsProviderRef);

	[super dealloc];
}

- (void) updateFb
{
	[self setNeedsDisplayInRect:NSMakeRect(0, 0, mWidth, mHeight)];
}

int lastKeyCode = -1;

int keyEventToCode(NSEvent *event)
{
	int code = [event keyCode];
	switch (code)
	{
		// Arrow keys
		case 123:
		case 124:
		case 125:
		case 126:
			break;
			
		default:
			code = [[event characters] UTF8String][0];
	}	

	return code;
}

- (void) keyDown:(NSEvent *)event
{
	int code = keyEventToCode(event);
	if (code != lastKeyCode)
	{
		lastKeyCode = code;	// Suppress autorepeat
		enqueueKey(0x80000000 | code);
	}
}

- (void) keyUp:(NSEvent *)event
{
	lastKeyCode = -1;
	enqueueKey(keyEventToCode(event));
}

- (BOOL) acceptsFirstResponser
{
	return YES;
}

- (void) drawRect:(NSRect) rect
{
	CGContextRef viewContextRef = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSetInterpolationQuality(viewContextRef, kCGInterpolationNone);
	CGContextSetShouldAntialias(viewContextRef, NO);

	if (mFbBitsProviderRef) 
	{
		CGImageRef imageRef = CGImageCreate(
			mWidth,
			mHeight,
			8, //bitsPerComponent
			32, //bitsPerPixel
			(mWidth * 4), //bytesPerRow
			CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), 
			kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst,
			mFbBitsProviderRef, //provider
			NULL, //decode
			0, //interpolate
			kCGRenderingIntentDefault); //intent
		CGContextDrawImage(viewContextRef, CGRectMake(0, 0, [self bounds].size.width, [self bounds].size.height), imageRef);
		CGImageRelease(imageRef);
	}
}

- (void) executeCode
{
	if (!runQuantum(mCore, -1, 500000))
	{
		printf("app terminated\n");
		[NSApp terminate: nil];
	}
	
	[self updateFb];
}

- (void) setCore: (Core*) core
{
	mCore = core;
}

@end

@interface SimAppController : NSObject
{
}
@end

@implementation SimAppController
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}
@end

void runUI(Core *core, int width, int height)
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	// Make foreground application with icon in task bar
	ProcessSerialNumber psn = { 0, kCurrentProcess };
	TransformProcessType(&psn, kProcessTransformToForegroundApplication);

	[NSApplication sharedApplication];

	NSView *mainView = [[FrameBufferView alloc] initWithFrame:NSMakeRect(0.0, 0.0, width, height)];
	if (!mainView) 
	{
		fprintf(stderr, "Couldn't allocate view\n");
		exit(1);
	}

	[mainView setCore:core];
	[mainView setFb: getCoreFb(core)];

	NSWindow *mainWindow = [[NSWindow alloc] initWithContentRect:[mainView frame]
		styleMask:NSTitledWindowMask|NSMiniaturizableWindowMask|NSClosableWindowMask
		backing:NSBackingStoreBuffered defer:NO];
	if (!mainWindow) 
	{
		fprintf(stderr, "(cocoa) can't create window\n");
		exit(1);
	}

	[NSApp activateIgnoringOtherApps:YES];
	
	[mainWindow setTitle:[NSString stringWithFormat:@"Framebuffer"]];
	[mainWindow setContentView:mainView];
	[mainWindow useOptimizedDrawing:YES];
	[mainWindow makeKeyAndOrderFront:mainWindow];
	[mainWindow center];
	[mainWindow makeFirstResponder: mainView];
	[NSTimer scheduledTimerWithTimeInterval:0
		target:mainView selector:@selector(executeCode)
		userInfo:nil repeats:YES];

    SimAppController *appController = [[SimAppController alloc] init];
    [NSApp setDelegate:appController];

	[NSApp run];

	[pool release];
}
