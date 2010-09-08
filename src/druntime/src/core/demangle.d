/**
 * The demangle module converts mangled D symbols to a representation similar
 * to what would have existed in code.
 *
 * Copyright: Copyright Sean Kelly 2010 - 2010.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Sean Kelly
 *
 *          Copyright Sean Kelly 2010 - 2010.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE_1_0.txt or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module core.demangle;


debug(trace) import core.stdc.stdio : printf;
debug(info) import core.stdc.stdio : printf;
import core.stdc.stdio : snprintf;
import core.stdc.string : memmove;
import core.stdc.stdlib : strtold;


/**
 * Demangles D mangled names.  If it is not a D mangled name, it returns its
 * argument name.
 *
 * Params:
 *  buf = The string to demangle.
 *  dst = An optional destination buffer.
 *
 * Returns:
 *  The demangled name or the original string if the name is not a mangled D
 *  name.
 */
char[] demangle( const(char)[] buf, char[] dst = null )
{
    // NOTE: This implementation currently only works with mangled function
    //       names as they exist in an object file.  Type names mangled via
    //       the .mangleof property are effectively incomplete as far as the
    //       ABI is concerned and so are not considered to be mangled symbol
    //       names.

    // NOTE: This implementation builds the demangled buffer in place by
    //       writing data as it is decoded and then rearranging it later as
    //       needed.  In practice this results in very little data movement,
    //       and the performance cost is more than offset by the gain from
    //       not allocating dynamic memory to assemble the name piecemeal.
    //
    //       If the destination buffer is too small, parsing will restart
    //       with a larger buffer.  Since this generally means only one
    //       allocation during the course of a parsing run, this is still
    //       faster than assembling the result piecemeal.

    enum minBufSize = 4000;

    size_t  pos = 0;
    size_t  len = 0;
    
    static class ParseException : Exception
    {
        this( string msg )
        {
            super( msg );
        }
    }
    
    static class OverflowException : Exception
    {
        this( string msg )
        {
            super( msg );
        }
    }
    
    static void error( string msg = "Invalid symbol" )
    {
        //throw new ParseException( msg );
        debug(info) printf( "error: %.*s\n", cast(int) msg.length, msg.ptr );
        throw cast(ParseException) cast(void*) ParseException.classinfo.init;
        
    }
    
    static void overflow( string msg = "Buffer overflow" )
    {
        //throw new OverflowException( msg );
        debug(info) printf( "overflow: %.*s\n", cast(int) msg.length, msg.ptr );
        throw cast(OverflowException) cast(void*) OverflowException.classinfo.init;
    }
    
    //////////////////////////////////////////////////////////////////////////
    // Type Testing and Conversion
    //////////////////////////////////////////////////////////////////////////
    
    static bool isDigit( char val )
    {
        return '0' <= val && '9' >= val;
    }
    
    static bool isHexDigit( char val )
    {
        return ('0' <= val && '9' >= val) ||
               ('a' <= val && 'f' >= val) ||
               ('A' <= val && 'F' >= val);
    }
    
    static bool isAlpha( char val )
    {
        return ('a' <= val && 'z' >= val) ||
               ('A' <= val && 'Z' >= val);
    }
    
    static ubyte ascii2hex( char val )
    {
        switch( val )
        {
        case 'a': .. case 'f':
            return cast(ubyte)(val - 'a' + 10);
        case 'A': .. case 'F':
            return cast(ubyte)(val - 'A' + 10);
        case '0': .. case '9':
            return cast(ubyte)(val - '0');
        default:
            error();
            return 0;
        }
    }
    
    //////////////////////////////////////////////////////////////////////////
    // Data Output
    //////////////////////////////////////////////////////////////////////////
    
    static bool contains( const(char)[] a, const(char)[] b )
    {
        return a.length &&
               b.ptr >= a.ptr &&
               b.ptr + b.length <= a.ptr + a.length;
    }
    
    char[] shift( const(char)[] val )
    {
        void exch( size_t a, size_t b )
        {
            char t = dst[a];
            dst[a] = dst[b];
            dst[b] = t;
        }

        if( val.length )
        {
            assert( contains( dst[0 .. len], val ) );
            debug(info) printf( "shifting (%.*s)\n", cast(int) val.length, val.ptr );
            
            for( size_t n = 0; n < val.length; n++ )
            {
                for( auto v = val.ptr - dst.ptr; v + 1 < len; v++ )
                {
                    exch( v, v + 1 );
                }
            }
            return dst[len - val.length .. len];
        }
        return null;
    }
    
    char[] append( const(char)[] val )
    {
        if( val.length )
        {
            if( !dst.length )
                dst.length = minBufSize;
            assert( !contains( dst[0 .. len], val ) );
            debug(info) printf( "appending (%.*s)\n", cast(int) val.length, val.ptr );
        
            if( dst.length - len >= val.length )
            {
                dst[len .. len + val.length] = val[];
                auto t = dst[len .. len + val.length];
                len += val.length;
                return t;
            }
            overflow();
        }
        return null;
    }

    char[] put( const(char)[] val )
    {
        if( val.length )
        {
            if( !contains( dst[0 .. len], val ) )
                return append( val );
            return shift( val );
        }
        return null;
    }
    
    void pad( const(char)[] val )
    {
        if( val.length )
        {
            append( " " );
            put( val );
        }
    }

    void silent( lazy void dg )
    {
        debug(trace) printf( "silent+\n" );
        debug(trace) scope(success) printf( "silent-\n" );
        auto n = len; dg(); len = n;
    }
    
    //////////////////////////////////////////////////////////////////////////
    // Parsing Utility
    //////////////////////////////////////////////////////////////////////////

    char tok()
    {
        if( pos < buf.length )
            return buf[pos];
        return char.init;
    }
    
    void test( char val )
    {
        if( val != tok() )
            error();
    }
    
    void next()
    {
        if( pos++ >= buf.length )
            error();
    }
    
    void match( char val )
    {
        test( val );
        next();
    }
    
    void matchS( const(char)[] val )
    {
        foreach( e; val )
        {
            test( e );
            next();
        }
    }
    
    void eat( char val )
    {
        if( val == tok() )
            next();
    }
    
    //////////////////////////////////////////////////////////////////////////
    // Parsing Implementation
    //////////////////////////////////////////////////////////////////////////

    /*
    Number:
        Digit
        Digit Number
    */
    const(char)[] sliceNumber()
    {
        debug(trace) printf( "sliceNumber+\n" );
        debug(trace) scope(success) printf( "sliceNumber-\n" );

        auto beg = pos;

        while( true )
        {
            switch( tok() )
            {
            case '0': .. case '9':
                next();
                continue;
            default:
                return buf[beg .. pos];
            }
        }    
    }

    size_t decodeNumber()
    {
        debug(trace) printf( "decodeNumber+\n" );
        debug(trace) scope(success) printf( "decodeNumber-\n" );

        auto   num = sliceNumber();
        size_t val = 0;
        
        foreach( i, e; num )
        {
            size_t n = e - '0';
            if( val > (val.max - n) / 10 )
                error();
            val = val * 10 + n;
        }
        return val;
    }

    void parseReal()
    {
        debug(trace) printf( "parseReal+\n" );
        debug(trace) scope(success) printf( "parseReal-\n" );

        char[64] tbuf = void;
        size_t   tlen = 0;
        real     val  = void;
        
        if( 'N' == tok() )
        {
            tbuf[tlen++] = '-';
            next();
        }
        tbuf[tlen++] = '0';
        tbuf[tlen++] = 'X';
        if( !isHexDigit( tok() ) )
            error( "Expected hex digit" );
        tbuf[tlen++] = tok();
        tbuf[tlen++] = '.';
        next();
        
        while( isHexDigit( tok() ) )
        {
            tbuf[tlen++] = tok();
            next();
        }
        match( 'P' );
        if( 'N' == tok() )
        {
            tbuf[tlen++] = '-';
            next();
        }
        else
        {
            tbuf[tlen++] = '+';
        }
        while( isDigit( tok() ) )
        {
            tbuf[tlen++] = tok();
            next();
        }
        
        tbuf[tlen] = 0;
        debug(info) printf( "got (%s)\n", tbuf.ptr );
        val = strtold( tbuf.ptr, null );
        tlen = snprintf( tbuf.ptr, tbuf.length, "%Lf", val );
        debug(info) printf( "converted (%.*s)\n", cast(int) tlen, tbuf.ptr );
        put( tbuf[0 .. tlen] );
    }
    
    /*
    LName:
        Number Name
        
    Name:
        Namestart
        Namestart Namechars

    Namestart:
        _
        Alpha

    Namechar:
        Namestart
        Digit

    Namechars:
        Namechar
        Namechar Namechars
    */
    void parseLName()
    {
        debug(trace) printf( "parseLName+\n" );
        debug(trace) scope(success) printf( "parseLName-\n" );

        auto n = decodeNumber();

        if( !n || n > buf.length || n > buf.length - pos )
            error( "LName must be at least 1 character" );
        if( '_' != tok() && !isAlpha( tok() ) )
            error( "Invalid character in LName" );
        foreach( e; buf[pos + 1 .. pos + n] )
        {
            if( '_' != e && !isAlpha( e ) && !isDigit( e ) )
                error( "Invalid character in LName" );
        }

        put( buf[pos .. pos + n] );
        pos += n;
    }
    
    /*
    Type:
        Shared
        Const
        Immutable
        Wild
        TypeArray
        TypeNewArray
        TypeStaticArray
        TypeAssocArray
        TypePointer
        TypeFunction
        TypeIdent
        TypeClass
        TypeStruct
        TypeEnum
        TypeTypedef
        TypeDelegate
        TypeNone
        TypeVoid
        TypeByte
        TypeUbyte
        TypeShort
        TypeUshort
        TypeInt
        TypeUint
        TypeLong
        TypeUlong
        TypeFloat
        TypeDouble
        TypeReal
        TypeIfloat
        TypeIdouble
        TypeIreal
        TypeCfloat
        TypeCdouble
        TypeCreal
        TypeBool
        TypeChar
        TypeWchar
        TypeDchar
        TypeTuple

    Shared:
        O Type

    Const:
        x Type

    Immutable:
        y Type

    Wild:
        Ng Type

    TypeArray:
        A Type

    TypeNewArray:
        Ne Type

    TypeStaticArray:
        G Number Type

    TypeAssocArray:
        H Type Type

    TypePointer:
        P Type

    TypeFunction:
        CallConvention FuncAttrs Arguments ArgClose Type

    TypeIdent:
        I LName

    TypeClass:
        C LName

    TypeStruct:
        S LName

    TypeEnum:
        E LName

    TypeTypedef:
        T LName

    TypeDelegate:
        D TypeFunction

    TypeNone:
        n

    TypeVoid:
        v

    TypeByte:
        g

    TypeUbyte:
        h

    TypeShort:
        s

    TypeUshort:
        t

    TypeInt:
        i

    TypeUint:
        k

    TypeLong:
        l

    TypeUlong:
        m

    TypeFloat:
        f

    TypeDouble:
        d

    TypeReal:
        e

    TypeIfloat:
        o

    TypeIdouble:
        p

    TypeIreal:
        j

    TypeCfloat:
        q

    TypeCdouble:
        r

    TypeCreal:
        c

    TypeBool:
        b

    TypeChar:
        a

    TypeWchar:
        u

    TypeDchar:
        w

    TypeTuple:
        B Number Arguments
    */
    char[] parseType( char[] name = null )
    {
        debug(trace) printf( "parseType+\n" );
        debug(trace) scope(success) printf( "parseType-\n" );
        
        enum IsDelegate { yes, no }
        
        auto beg = len;
        
        /*
        TypeFunction:
            CallConvention FuncAttrs Arguments ArgClose Type

        CallConvention:
            F       // D
            U       // C
            W       // Windows
            V       // Pascal
            R       // C++

        FuncAttrs:
            FuncAttr
            FuncAttr FuncAttrs

        FuncAttr:
            empty
            FuncAttrPure
            FuncAttrNothrow
            FuncAttrProperty
            FuncAttrRef
            FuncAttrTrusted
            FuncAttrSafe

        FuncAttrPure:
            Na

        FuncAttrNothrow:
            Nb

        FuncAttrRef:
            Nc

        FuncAttrProperty:
            Nd

        FuncAttrTrusted:
            Ne

        FuncAttrSafe:
            Nf

        Arguments:
            Argument
            Argument Arguments

        Argument:
            Argument2
            M Argument2     // scope

        Argument2:
            Type
            J Type     // out
            K Type     // ref
            L Type     // lazy

        ArgClose
            X     // variadic T t,...) style
            Y     // variadic T t...) style
            Z     // not variadic
        */
        void parseTypeFunction( IsDelegate isdg = IsDelegate.no )
        {
            debug(trace) printf( "parseTypeFunction+\n" );
            debug(trace) scope(success) printf( "parseTypeFunction-\n" );
        
            // CallConvention
            switch( tok() )
            {
            case 'F': // D
                next();
                break;
            case 'U': // C
                next();
                put( "extern (C) " );
                break;
            case 'W': // Windows
                next();
                put( "extern (Windows) " );
                break;
            case 'V': // Pascal
                next();
                put( "extern (Pascal) " );
                break;
            case 'R': // C++
                next();
                put( "extern (C++) " );
                break;
            default:
                error();
            }

            // FuncAttrs
            while( 'N' == tok() )
            {
                next();
                switch( tok() )
                {
                case 'a': // FuncAttrPure
                    next();
                    put( "pure " );
                    continue;
                case 'b': // FuncAttrNoThrow
                    next();
                    put( "nothrow " );
                    continue;
                case 'c': // FuncAttrRef
                    next();
                    put( "ref " );
                    continue;
                case 'd': // FuncAttrProperty
                    next();
                    put( "@property " );
                    continue;
                case 'e': // FuncAttrTrusted
                    next();
                    put( "@trusted " );
                    continue;
                case 'f': // FuncAttrSafe
                    next();
                    put( "@safe " );
                    continue;
                default:
                    error();
                }
            }
            
            beg = len;
            put( "(" );
            scope(success)
            {
                put( ")" );
                auto t = len;
                parseType();
                put( " " );
                if( name.length )
                {
                    if( !contains( dst[0 .. len], name ) )
                        put( name );
                    else if( shift( name ).ptr != name.ptr )
                    {
                        beg -= name.length;
                        t -= name.length;
                    }
                }
                else if( IsDelegate.yes == isdg )
                    put( "delegate" );
                else
                    put( "function" );
                shift( dst[beg .. t] );
            }

            // Arguments
            for( size_t n = 0; true; n++ )
            {
                debug(info) printf( "tok (%c)\n", tok() );
                switch( tok() )
                {
                case 'X': // ArgClose (variadic T t,...) style)
                    next();
                    put( ", ..." );
                    return;
                case 'Y': // ArgClose (variadic T t...) style)
                    next();
                    put( "..." );
                    return;
                case 'Z': // ArgClose (not variadic)
                    next();
                    return;
                default:
                    break;
                }
                if( n )
                {
                    put( ", " );
                }
                if( 'M' == tok() )
                {
                    next();
                    put( "scope " );
                }
                switch( tok() )
                {
                case 'J': // out (J Type)
                    next();
                    put( "out " );
                    parseType();
                    continue;
                case 'K': // ref (K Type)
                    next();
                    put( "ref " );
                    parseType();
                    continue;
                case 'L': // lazy (L Type) 
                    next();
                    put( "lazy " );
                    parseType();
                    continue;
                default:
                    parseType();
                }
            }
        }

        switch( tok() )
        {
        case 'O': // Shared (O Type)
            next();
            put( "shared(" );
            parseType();
            put( ")" );
            pad( name );
            return dst[beg .. len];
        case 'x': // Const (x Type)
            next();
            put( "const(" );
            parseType();
            put( ")" );
            pad( name );
            return dst[beg .. len];
        case 'y': // Immutable (y Type)
            next();
            put( "immutable(" );
            parseType();
            put( ")" );
            pad( name );
            return dst[beg .. len];
        case 'N':
            next();
            switch( tok() )
            {
            case 'g': // Wild (Ng Type)
                next();
                // TODO: Anything needed here?
                parseType();
                return dst[beg .. len];
            case 'e': // TypeNewArray (Ne Type)
                next();
                // TODO: Anything needed here?
                parseType();
                return dst[beg .. len];
            default:
                error();
            }
        case 'A': // TypeArray (A Type)
            next();
            parseType();
            put( "[]" );
            pad( name );
            return dst[beg .. len];
        case 'G': // TypeStaticArray (G Number Type)
            next();
            auto num = sliceNumber();
            parseType();
            put( "[" );
            put( num );
            put( "]" );
            pad( name );
            return dst[beg .. len];
        case 'H': // TypeAssocArray (H Type Type)
            next();
            // skip t1
            auto t = parseType();
            parseType();
            put( "[" );
            put( t );
            put( "]" );
            pad( name );
            return dst[beg .. len];
        case 'P': // TypePointer (P Type)
            next();
            parseType();
            put( "*" );
            pad( name );
            return dst[beg .. len];
        case 'F': case 'U': case 'W': case 'V': case 'R': // TypeFunction
            parseTypeFunction();
            return dst[beg .. len];
        case 'I': // TypeIdent (I LName)
        case 'C': // TypeClass (C LName)
        case 'S': // TypeStruct (S LName)
        case 'E': // TypeEnum (E LName)
        case 'T': // TypeTypedef (T LName)
            next();
            parseLName();
            return dst[beg .. len];
        case 'D': // TypeDelegate (D TypeFunction)
            next();
            parseTypeFunction( IsDelegate.yes );
            return dst[beg .. len];
        case 'n': // TypeNone (n)
            next();
            // TODO: Anything needed here?
            return dst[beg .. len];
        case 'v': // TypeVoid (v)
            next();
            put( "void" );
            return dst[beg .. len];
        case 'g': // TypeByte (g)
            next();
            put( "byte" );
            pad( name );
            return dst[beg .. len];
        case 'h': // TypeUbyte (h)
            next();
            put( "ubyte" );
            pad( name );
            return dst[beg .. len];
        case 's': // TypeShort (s)
            next();
            put( "short" );
            pad( name );
            return dst[beg .. len];
        case 't': // TypeUshort (t)
            next();
            put( "ushort" );
            pad( name );
            return dst[beg .. len];
        case 'i': // TypeInt (i)
            next();
            put( "int" );
            pad( name );
            return dst[beg .. len];
        case 'k': // TypeUint (k)
            next();
            put( "uint" );
            pad( name );
            return dst[beg .. len];
        case 'l': // TypeLong (l)
            next();
            put( "long" );
            pad( name );
            return dst[beg .. len];
        case 'm': // TypeUlong (m)
            next();
            put( "ulong" );
            pad( name );
            return dst[beg .. len];
        case 'f': // TypeFloat (f)
            next();
            put( "float" );
            pad( name );
            return dst[beg .. len];
        case 'd': // TypeDouble (d)
            next();
            put( "double" );
            pad( name );
            return dst[beg .. len];
        case 'e': // TypeReal (e)
            next();
            put( "real" );
            pad( name );
            return dst[beg .. len];
        case 'o': // TypeIfloat (o)
            next();
            put( "ifloat" );
            pad( name );
            return dst[beg .. len];
        case 'p': // TypeIdouble (p)
            next();
            put( "idouble" );
            pad( name );
            return dst[beg .. len];
        case 'j': // TypeIreal (j)
            next();
            put( "ireal" );
            pad( name );
            return dst[beg .. len];
        case 'q': // TypeCfloat (q)
            next();
            put( "cfloat" );
            pad( name );
            return dst[beg .. len];
        case 'r': // TypeCdouble (r)
            next();
            put( "cdouble" );
            pad( name );
            return dst[beg .. len];
        case 'c': // TypeCreal (c)
            next();
            put( "creal" );
            pad( name );
            return dst[beg .. len];
        case 'b': // TypeBool (b)
            next();
            put( "bool" );
            pad( name );
            return dst[beg .. len];
        case 'a': // TypeChar (a)
            next();
            put( "char" );
            pad( name );
            return dst[beg .. len];
        case 'u': // TypeWchar (u)
            next();
            put( "wchar" );
            pad( name );
            return dst[beg .. len];
        case 'w': // TypeDchar (w)
            next();
            put( "dchar" );
            pad( name );
            return dst[beg .. len];
        case 'B': // TypeTuple (B Number Arguments)
            next();
            // TODO: Handle this.
            return dst[beg .. len];
        default:
            error(); return null;
        }
    }
    
    /*
    Value:
        n
        Number
        i Number
        N Number
        e HexFloat
        c HexFloat c HexFloat
        A Number Value...

    HexFloat:
        NAN
        INF
        NINF
        N HexDigits P Exponent
        HexDigits P Exponent

    Exponent:
        N Number
        Number

    HexDigits:
        HexDigit
        HexDigit HexDigits

    HexDigit:
        Digit
        A
        B
        C
        D
        E
        F
    */
    void parseValue()
    {
        debug(trace) printf( "parseValue+\n" );
        debug(trace) scope(success) printf( "parseValue-\n" );

        switch( tok() )
        {
        case 'n':
            next();
            put( "null" );
            return;
        case 'i':
            next();
            if( '0' > tok() || '9' < tok() )
                error( "Number expected" );
            // fall-through intentional
        case '0': .. case '9':
            put( sliceNumber() );
            return;
        case 'N':
            next();
            put( "-" );
            put( sliceNumber() );
            return;
        case 'e':
            next();
            parseReal();
            return;
        case 'c':
            next();
            parseReal();
            put( "+" );
            parseReal();
            put( "i" );
            return;
        case 'a': case 'w': case 'd':
            char t = tok();
            next();
            auto n = decodeNumber();
            match( '_' );
            put( "\"" );
            for( auto i = 0; i < n; i++ )
            {
                auto a = ascii2hex( tok() ); next();
                auto b = ascii2hex( tok() ); next();
                auto v = cast(char)((a << 4) | b); 
                put( (cast(char*) &v)[0 .. 1] );
            }
            put( "\"" );
            if( 'a' != tok() )
                put( (cast(char*) &t)[0 .. 1] );
            return;
        case 'A':
            // A Number Value...
            // An array literal. Value is repeated Number times.
            error(); // TODO: Not implemented.
        default:
            error();
        }
    }
    
    /*
    TemplateArgs:
        TemplateArg
        TemplateArg TemplateArgs

    TemplateArg:
        T Type
        V Type Value
        S LName
    */
    void parseTemplateArgs()
    {
        debug(trace) printf( "parseTemplateArgs+\n" );
        debug(trace) scope(success) printf( "parseTemplateArgs-\n" );

        for( size_t n = 0; true; n++ )
        {
            switch( tok() )
            {
            case 'T':
                next();
                if( n ) put( ", " );
                parseType();
                continue;
            case 'V':
                next();
                if( n ) put( ", " );
                silent( parseType() );
                parseValue();
                continue;
            case 'S':
                next();
                if( n ) put( ", " );
                parseLName();
                continue;
            default:
                return;
            }
        }
    }
    
    /*
    TemplateInstanceName:
        Number __T LName TemplateArgs Z
    */
    void parseTemplateInstanceName()
    {
        debug(trace) printf( "parseTemplateInstanceName+\n" );
        debug(trace) scope(success) printf( "parseTemplateInstanceName-\n" );

        auto sav = pos;
        scope(failure) pos = sav;
        auto n = decodeNumber();
        auto beg = pos;
        matchS( "__T" );
        parseLName();
        put( "!(" );
        parseTemplateArgs();
        match( 'Z' );
        if( pos - beg != n )
            error( "Template name length mismatch" );
        put( ")" );
    }
    
    bool mayBeTemplateInstanceName()
    {
        debug(trace) printf( "mayBeTemplateInstanceName+\n" );
        debug(trace) scope(success) printf( "mayBeTemplateInstanceName-\n" );

        auto p = pos;
        scope(exit) pos = p;
        auto n = decodeNumber();
        return n >= 5 &&
               pos < buf.length && '_' == buf[pos++] &&
               pos < buf.length && '_' == buf[pos++] &&
               pos < buf.length && 'T' == buf[pos++];
    }
    
    /*
    SymbolName:
        LName
        TemplateInstanceName
    */
    void parseSymbolName()
    {
        debug(trace) printf( "parseSymbolName+\n" );
        debug(trace) scope(success) printf( "parseSymbolName-\n" );

        // LName -> Number
        // TemplateInstanceName -> Number "__T"
        switch( tok() )
        {
        case '0': .. case '9':
            if( mayBeTemplateInstanceName() )
            {
                auto t = len;

                try
                {
                    debug(trace) printf( "may be template instance name\n" );
                    parseTemplateInstanceName();
                    return;
                }
                catch( ParseException e )
                {
                    debug(trace) printf( "not a template instance name\n" );
                    len = t;
                }
            }
            parseLName();
            return;
        default:
            error();
        }
    }
    
    /*
    QualifiedName:
        SymbolName
        SymbolName QualifiedName
    */
    char[] parseQualifiedName()
    {
        debug(trace) printf( "parseQualifiedName+\n" );
        debug(trace) scope(success) printf( "parseQualifiedName-\n" );
        size_t  beg = len;
        size_t  n   = 0;

        do
        {
            if( n++ )
                put( "." );
            parseSymbolName();
        } while( isDigit( tok() ) );
        return dst[beg .. len];
    }

    /*
    MangledName:
        _D QualifiedName Type
        _D QualifiedName M Type
    */
    void parseMangledName()
    {
        debug(trace) printf( "parseMangledName+\n" );
        debug(trace) scope(success) printf( "parseMangledName-\n" );
        char[] name = null;

        eat( '_' );
        match( 'D' );
        name = parseQualifiedName();
        debug(info) printf( "name (%.*s)\n", cast(int) name.length, name.ptr );
        if( 'M' == tok() )
            next(); // has 'this' pointer
        parseType( name );
    }
    
    while( true )
    {
        try
        {
            debug(info) printf( "demangle(%.*s)\n", cast(int) buf.length, buf.ptr );
            parseMangledName();
            return dst[0 .. len];
        }
        catch( OverflowException e )
        {
            debug(trace) printf( "overflow... restarting\n" );
            auto a = minBufSize;
            auto b = 2 * dst.length;
            auto newsz = a < b ? b : a;
            debug(info) printf( "growing dst to %lu bytes\n", newsz );
            dst.length = newsz;
            pos = len = 0;
            continue;
        }
        catch( ParseException e )
        {
            debug
            {
                auto msg = e.toString;
                printf( "error: %.*s\n", cast(int) msg.length, msg.ptr );
            }
            if( dst.length < buf.length )
                dst.length = buf.length;
            dst[0 .. buf.length] = buf[];
            return dst[0 .. buf.length];
        }
    }
}


unittest
{
    static string[2][] table =
    [
        [ "printf",      "printf" ],
        [ "_foo",        "_foo" ],
        [ "_D88",        "_D88" ],
        [ "_D4test3fooAa", "char[] test.foo"],
        [ "_D8demangle8demangleFAaZAa", "char[] demangle.demangle(char[])" ],
        [ "_D6object6Object8opEqualsFC6ObjectZi", "int object.Object.opEquals(class Object)" ],
        [ "_D4test2dgDFiYd", "double delegate(int, ...) test.dg" ],
        //[ "_D4test58__T9factorialVde67666666666666860140VG5aa5_68656c6c6fVPvnZ9factorialf", "float test.factorial!(double 4.2, char[5] \"hello\"c, void* null).factorial" ],
        //[ "_D4test101__T9factorialVde67666666666666860140Vrc9a999999999999d9014000000000000000c00040VG5aa5_68656c6c6fVPvnZ9factorialf", "float test.factorial!(double 4.2, cdouble 6.8+3i, char[5] \"hello\"c, void* null).factorial" ],
        [ "_D4test34__T3barVG3uw3_616263VG3wd3_646566Z1xi", "int test.bar!(wchar[3] \"abc\"w, dchar[3] \"def\"d).x" ],
        [ "_D8demangle4testFLC6ObjectLDFLiZiZi", "int demangle.test(lazy class Object, lazy int delegate(lazy int))"],
        [ "_D8demangle4testFAiXi", "int demangle.test(int[] ...)"],
        [ "_D8demangle4testFLAiXi", "int demangle.test(lazy int[] ...)"],
        [ "_D6plugin8generateFiiZAya", "immutable(char)[] plugin.generate(int, int)"],
        [ "_D6plugin8generateFiiZAxa", "const(char)[] plugin.generate(int, int)"],
        [ "_D6plugin8generateFiiZAOa", "shared(char)[] plugin.generate(int, int)"]
    ];

    foreach( i, name; table )
    {
        auto r = demangle( name[0] );
        /*
        assert(r == name[1],
                "table entry #" ~ to!string(i) ~ ": '" ~ name[0]
                ~ "' demangles as '" ~ r ~ "' but is expected to be '"
                ~ name[1] ~ "'");
        */
    }
}
