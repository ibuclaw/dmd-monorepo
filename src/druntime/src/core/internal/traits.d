/**
 * Contains traits for runtime internal usage.
 *
 * Copyright: Copyright Digital Mars 2014 -.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Martin Nowak
 * Source: $(DRUNTIMESRC core/internal/_traits.d)
 */
module core.internal.traits;

/// taken from std.typetuple.TypeTuple
template TypeTuple(TList...)
{
    alias TypeTuple = TList;
}

T trustedCast(T, U)(auto ref U u) @trusted pure nothrow
{
    return cast(T)u;
}

template Unconst(T)
{
         static if (is(T U ==   immutable U)) alias Unconst = U;
    else static if (is(T U == inout const U)) alias Unconst = U;
    else static if (is(T U == inout       U)) alias Unconst = U;
    else static if (is(T U ==       const U)) alias Unconst = U;
    else                                      alias Unconst = T;
}

/// taken from std.traits.Unqual
template Unqual(T)
{
    version (none) // Error: recursive alias declaration @@@BUG1308@@@
    {
             static if (is(T U ==     const U)) alias Unqual = Unqual!U;
        else static if (is(T U == immutable U)) alias Unqual = Unqual!U;
        else static if (is(T U ==     inout U)) alias Unqual = Unqual!U;
        else static if (is(T U ==    shared U)) alias Unqual = Unqual!U;
        else                                    alias Unqual =        T;
    }
    else // workaround
    {
             static if (is(T U ==          immutable U)) alias Unqual = U;
        else static if (is(T U == shared inout const U)) alias Unqual = U;
        else static if (is(T U == shared inout       U)) alias Unqual = U;
        else static if (is(T U == shared       const U)) alias Unqual = U;
        else static if (is(T U == shared             U)) alias Unqual = U;
        else static if (is(T U ==        inout const U)) alias Unqual = U;
        else static if (is(T U ==        inout       U)) alias Unqual = U;
        else static if (is(T U ==              const U)) alias Unqual = U;
        else                                             alias Unqual = T;
    }
}

/// used to declare an extern(D) function that is defined in a different module
template externDFunc(string fqn, T:FT*, FT) if(is(FT == function))
{
    static if (is(FT RT == return) && is(FT Args == function))
    {
        import core.demangle : mangleFunc;
        enum decl = {
            string s = "extern(D) RT bug13050(Args)";
            foreach (attr; __traits(getFunctionAttributes, FT))
                s ~= " " ~ attr;
            return s ~ ";";
        }();
        pragma(mangle, mangleFunc!T(fqn)) mixin(decl);
        alias externDFunc = bug13050;
    }
    else
        static assert(0);
}
