// 
// Copyright (C) 2011-2014 Jeff Bush
// 
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Library General Public
// License as published by the Free Software Foundation; either
// version 2 of the License, or (at your option) any later version.
// 
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Library General Public License for more details.
// 
// You should have received a copy of the GNU Library General Public
// License along with this library; if not, write to the
// Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
// Boston, MA  02110-1301, USA.
// 


#ifndef __RENDER_TARGET_H
#define __RENDER_TARGET_H

#include "RenderUtils.h"
#include "Surface.h"

namespace render
{

class RenderTarget
{
public:
	RenderTarget()
	    :   fColorBuffer(0),
	        fZBuffer(0)
	{
	}
	
	void setColorBuffer(Surface *buffer)
	{
	    fColorBuffer = buffer;
	}
	
	void setZBuffer(Surface *buffer)
	{
	    fZBuffer = buffer;
	}

	Surface *getColorBuffer()
	{
		return fColorBuffer;
	}

	Surface *getZBuffer()
	{
		return fZBuffer;
	}

private:
    Surface *fColorBuffer;
    Surface *fZBuffer;    
};

}

#endif
