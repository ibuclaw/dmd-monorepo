/**
 * Implementation of dynamic array property support routines.
 *
 * Copyright: Copyright Digital Mars 2000 - 2015.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Walter Bright
 * Source: $(DRUNTIMESRC rt/_adi.d)
 */

module rt.adi;

//debug=adi;            // uncomment to turn on debugging printf's

private
{
    debug(adi) import core.stdc.stdio;
}

/***************************************
 * Support for array equality test.
 * Returns:
 *      1       equal
 *      0       not equal
 */

extern (C) int _adEq2(void[] a1, void[] a2, TypeInfo ti)
{
    debug(adi) printf("_adEq2(a1.length = %d, a2.length = %d)\n", a1.length, a2.length);
    if (a1.length != a2.length)
        return 0;               // not equal
    if (!ti.equals(&a1, &a2))
        return 0;
    return 1;
}

@safe unittest
{
    debug(adi) printf("array.Eq unittest\n");

    struct S(T) { T val; }
    alias String = S!string;
    alias Float = S!float;

    String[1] a = [String("hello"c)];

    assert(a != [String("hel")]);
    assert(a != [String("helloo")]);
    assert(a != [String("betty")]);
    assert(a == [String("hello")]);
    assert(a != [String("hxxxx")]);

    Float[1] fa = [Float(float.nan)];
    assert(fa != fa);
}
