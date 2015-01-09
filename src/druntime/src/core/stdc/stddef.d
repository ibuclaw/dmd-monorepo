/**
 * D header file for C99.
 *
 * This contains bindings to selected types and functions from the standard C
 * header $(LINK2 http://pubs.opengroup.org/onlinepubs/009695399/basedefs/stddef.h.html, <stddef.h>). Note
 * that this is not automatically generated, and may omit some types/functions
 * from the original C header.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2009.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Sean Kelly
 * Source:    $(DRUNTIMESRC core/stdc/_stddef.d)
 * Standards: ISO/IEC 9899:1999 (E)
 */

module core.stdc.stddef;

extern (C):
@trusted: // Types only.
nothrow:
@nogc:

// size_t and ptrdiff_t are defined in the object module.

version( Windows )
{
    ///
    alias wchar wchar_t;
}
else
{
    ///
    alias dchar wchar_t;
}
