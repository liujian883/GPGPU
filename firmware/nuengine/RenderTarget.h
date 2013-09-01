// 
// Copyright 2013 Jeff Bush
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// 

#ifndef __RENDER_TARGET_H
#define __RENDER_TARGET_H

#include "Debug.h"
#include "vectypes.h"
#include "utils.h"

const int kTileSize = 64;
const int kBytesPerPixel = 4;
const int kCacheLineSize = 64;

class RenderTarget
{
public:
	RenderTarget(int fbBase, int fbWidth, int fbHeight)
		:	fWidth(fbWidth),
			fHeight(fbHeight),
			fStride(fbWidth * 4),
			fBaseAddress(fbBase)
	{
		f4x4AtOrigin[0] = fbBase;
		f4x4AtOrigin[1] = fbBase + 4;
		f4x4AtOrigin[2] = fbBase + 8; 
		f4x4AtOrigin[3] = fbBase + 12;
		f4x4AtOrigin[4] = fbBase + (fbWidth * 4);
		f4x4AtOrigin[5] = fbBase + (fbWidth * 4) + 4;
		f4x4AtOrigin[6] = fbBase + (fbWidth * 4) + 8; 
		f4x4AtOrigin[7] = fbBase + (fbWidth * 4) + 12;
		f4x4AtOrigin[8] = fbBase + (fbWidth * 8);
		f4x4AtOrigin[9] = fbBase + (fbWidth * 8) + 4;
		f4x4AtOrigin[10] = fbBase + (fbWidth * 8) + 8; 
		f4x4AtOrigin[11] = fbBase + (fbWidth * 8) + 12;
		f4x4AtOrigin[12] = fbBase + (fbWidth * 12);
		f4x4AtOrigin[13] = fbBase + (fbWidth * 12) + 4;
		f4x4AtOrigin[14] = fbBase + (fbWidth * 12) + 8; 
		f4x4AtOrigin[15] = fbBase + (fbWidth * 12) + 12;
	}

	void fillMasked(int left, int top, int mask, veci16 colors)
	{
		veci16 ptrs = f4x4AtOrigin + __builtin_vp_makevectori(left * 4 + top * fStride);
		__builtin_vp_scatter_storei_masked(ptrs, colors, mask);
	}
	
	void clearTile(int left, int top)
	{
		veci16 *ptr = (veci16*)(fBaseAddress + left * kBytesPerPixel + top * fWidth 
			* kBytesPerPixel);
		const veci16 kClearColor = __builtin_vp_makevectori(0);
		const int kStride = ((fWidth - kTileSize) * kBytesPerPixel / sizeof(veci16));
		for (int y = 0; y < kTileSize; y++)
		{
			for (int x = 0; x < kTileSize; x += 16)
				*ptr++ = kClearColor;
			
			ptr += kStride;
		}
	}
	
	void flushTile(int left, int top)
	{
		const int kStride = (fWidth - kTileSize) * kBytesPerPixel;
		unsigned int ptr = fBaseAddress + left * kBytesPerPixel + top * fWidth 
			* kBytesPerPixel;
		for (int y = 0; y < kTileSize; y++)
		{
			for (int x = 0; x < kTileSize; x += 16)
			{
				dflush(ptr);
				ptr += kCacheLineSize;
			}
			
			ptr += kStride;
		}
	}
	
	inline int getWidth() const 
	{
		return fWidth;
	}
	
	inline int getHeight() const
	{
		return fHeight;
	}

private:
	veci16 f4x4AtOrigin;
	int fWidth;
	int fHeight;
	int fStride;
	unsigned int fBaseAddress;
};

#endif