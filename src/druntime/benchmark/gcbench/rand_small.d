/**
 * Benchmark on uniformly distributed, random small allocations.
 *
 * Copyright: Copyright David Simcha 2011 - 2011.
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Authors:   David Simcha
 */

/*          Copyright David Simcha 2011 - 2011.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
import std.random, core.memory, std.stdio, std.conv;

void main(string[] args)
{
    size_t nIter = 1000;
    if(args.length > 1)
        nIter = to!size_t(args[1]);

    auto ptrs = new void*[4096];

    // Allocate large blocks with size uniformly distributed between 8
    // and 2048 bytes.
    foreach(i; 0..nIter) {
        foreach(ref ptr; ptrs) {
            ptr = GC.malloc(uniform(8, 2048), GC.BlkAttr.NO_SCAN);
        }
    }
}
