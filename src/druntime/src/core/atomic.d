/**
 * The atomic module provides basic support for lock-free
 * concurrent programming.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2010.
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Authors:   Sean Kelly
 * Source:    $(DRUNTIMESRC core/_atomic.d)
 */

/*          Copyright Sean Kelly 2005 - 2010.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE_1_0.txt or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module core.atomic;

version( D_InlineAsm_X86 )
{
    version = AsmX86;
    version = AsmX86_32;
    enum has64BitCAS = true;
}
version( D_InlineAsm_X86_64 )
{
    version = AsmX86;
    version = AsmX86_64;
    enum has64BitCAS = true;
}


private
{
    template NakedType(T: shared(T))  { alias T  NakedType; }
    template NakedType(T: shared(T*)) { alias T* NakedType; }
    template NakedType(T: const(T))   { alias T  NakedType; }
    template NakedType(T: const(T*))  { alias T* NakedType; }
    template NakedType(T: T*)         { alias T* NakedType; }
    template NakedType(T)             { alias T  NakedType; }
}


version( AsmX86 )
{
    // NOTE: Strictly speaking, the x86 supports atomic operations on
    //       unaligned values.  However, this is far slower than the
    //       common case, so such behavior should be prohibited.
    private bool atomicValueIsProperlyAligned(T)( size_t addr )
    {
        return addr % T.sizeof == 0;
    }
}


version( D_Ddoc )
{
    /**
     * Performs the binary operation 'op' on val using 'mod' as the modifier.
     *
     * Params:
     *  val = The target variable.
     *  mod = The modifier to apply.
     *
     * Returns:
     *  The result of the operation.
     */
    T atomicOp(string op, T, V1)( ref shared(T) val, V1 mod )
    {
        return val;
    }


    /**
     * Stores 'writeThis' to the memory referenced by 'here' if the value
     * referenced by 'here' is equal to 'ifThis'.  This operation is both
     * lock-free and atomic.
     *
     * Params:
     *  here      = The address of the destination variable.
     *  writeThis = The value to store.
     *  ifThis    = The comparison value.
     *
     * Returns:
     *  true if the store occurred, false if not.
     */
    bool cas(T,V1,V2)( shared(T)* here, const V1 ifThis, const V2 writeThis )
        if( is( NakedType!(V1) == NakedType!(T) ) &&
            is( NakedType!(V2) == NakedType!(T) ) )
    {
        return false;
    }
     
     
    /**
     * Loads 'val' from memory and returns it.  The memory barrier specified
     * by 'ms' is applied to the operation, which is fully sequenced by
     * default.
     *
     * Params:
     *  val = The target variable.
     *
     * Returns:
     *  The value of 'val'.
     */
    T atomicLoad(msync ms = msync.seq,T)( ref const shared(T) val )
    {
        return false;
    }
      
      
    /**
     * Writes 'newval' into 'val'.  The memory barrier specified by 'ms' is
     * applied to the operation, which is fully sequenced by default.
     *
     * Params:
     *  val    = The target variable.
     *  newval = The value to store.
     */
    void atomicStore(msync ms = msync.seq,T,V1)( ref shared(T) val, V1 newval )
        if( is( NakedType!(V1) == NakedType!(T) ) )
    {
        return false;
    }
       
    
    /**
     *
     */   
    enum msync
    {
        raw,    /// not sequenced
        acq,    /// hoist-load + hoist-store barrier
        rel,    /// sink-load + sink-store barrier
        seq,    /// fully sequenced (acq + rel)
    }
}
else version( AsmX86_32 )
{
    T atomicOp(string op, T, V1)( ref shared(T) val, V1 mod )
        if( is( NakedType!(V1) == NakedType!(T) ) )
    in
    {
        // NOTE: 32 bit x86 systems support 8 byte CAS, which only requires
        //       4 byte alignment, so use size_t as the align type here.
        static if( T.sizeof > size_t.sizeof )
            assert( atomicValueIsProperlyAligned!(size_t)( cast(size_t) &val ) );
        else
            assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
    }
    body
    {
        // binary operators
        //
        // +    -   *   /   %   ^^  &
        // |    ^   <<  >>  >>> ~   in
        // ==   !=  <   <=  >   >=
        static if( op == "+"  || op == "-"  || op == "*"  || op == "/"   ||
                   op == "%"  || op == "^^" || op == "&"  || op == "|"   ||
                   op == "^"  || op == "<<" || op == ">>" || op == ">>>" ||
                   op == "~"  || // skip "in"
                   op == "==" || op == "!=" || op == "<"  || op == "<="  ||
                   op == ">"  || op == ">=" )
        {
            T get = atomicLoad!(msync.raw)( val );
            mixin( "return get " ~ op ~ " mod;" );
        }
        else
        // assignment operators
        //
        // +=   -=  *=  /=  %=  ^^= &=
        // |=   ^=  <<= >>= >>>=    ~=
        static if( op == "+=" || op == "-="  || op == "*="  || op == "/=" ||
                   op == "%=" || op == "^^=" || op == "&="  || op == "|=" ||
                   op == "^=" || op == "<<=" || op == ">>=" || op == ">>>=" ) // skip "~="
        {
            T get, set;

            do
            {
                get = set = atomicLoad!(msync.raw)( val );
                mixin( "set " ~ op ~ " mod;" );
            } while( !cas( &val, get, set ) );
            return set;
        }
        else
        {
            static assert( false, "Operation not supported." );
        }
    }


    bool cas(T,V1,V2)( shared(T)* here, const V1 ifThis, const V2 writeThis )
        if( is( NakedType!(V1) == NakedType!(T) ) &&
            is( NakedType!(V2) == NakedType!(T) ) )
    in
    {
        // NOTE: 32 bit x86 systems support 8 byte CAS, which only requires
        //       4 byte alignment, so use size_t as the align type here.
        static if( T.sizeof > size_t.sizeof )
            assert( atomicValueIsProperlyAligned!(size_t)( cast(size_t) here ) );
        else
            assert( atomicValueIsProperlyAligned!(T)( cast(size_t) here ) );
    }
    body
    {
        static if( T.sizeof == byte.sizeof )
        {
            //////////////////////////////////////////////////////////////////
            // 1 Byte CAS
            //////////////////////////////////////////////////////////////////

            asm
            {
                mov DL, writeThis;
                mov AL, ifThis;
                mov ECX, here;
                lock; // lock always needed to make this op atomic
                cmpxchg [ECX], DL;
                setz AL;
            }
        }
        else static if( T.sizeof == short.sizeof )
        {
            //////////////////////////////////////////////////////////////////
            // 2 Byte CAS
            //////////////////////////////////////////////////////////////////

            asm
            {
                mov DX, writeThis;
                mov AX, ifThis;
                mov ECX, here;
                lock; // lock always needed to make this op atomic
                cmpxchg [ECX], DX;
                setz AL;
            }
        }
        else static if( T.sizeof == int.sizeof )
        {
            //////////////////////////////////////////////////////////////////
            // 4 Byte CAS
            //////////////////////////////////////////////////////////////////

            asm
            {
                mov EDX, writeThis;
                mov EAX, ifThis;
                mov ECX, here;
                lock; // lock always needed to make this op atomic
                cmpxchg [ECX], EDX;
                setz AL;
            }
        }
        else static if( T.sizeof == long.sizeof && has64BitCAS )
        {
            //////////////////////////////////////////////////////////////////
            // 8 Byte CAS on a 32-Bit Processor
            //////////////////////////////////////////////////////////////////

            asm
            {
                push EDI;
                push EBX;
                lea EDI, writeThis;
                mov EBX, [EDI];
                mov ECX, 4[EDI];
                lea EDI, ifThis;
                mov EAX, [EDI];
                mov EDX, 4[EDI];
                mov EDI, here;
                lock; // lock always needed to make this op atomic
                cmpxch8b [EDI];
                setz AL;
                pop EBX;
                pop EDI;
            }
        }
        else
        {
            static assert( false, "Invalid template type specified." );
        }
    }
    
    
    
    enum msync
    {
        raw,    /// not sequenced
        acq,    /// hoist-load + hoist-store barrier
        rel,    /// sink-load + sink-store barrier
        seq,    /// fully sequenced (acq + rel)
    }


    private
    {
        template isHoistOp(msync ms)
        {
            enum bool isHoistOp = ms == msync.acq ||
                                  ms == msync.seq;
        }


        template isSinkOp(msync ms)
        {
            enum bool isSinkOp = ms == msync.rel ||
                                 ms == msync.seq;
        }


        // NOTE: While x86 loads have acquire semantics for stores, it appears
        //       that independent loads may be reordered by some processors
        //       (notably the AMD64).  This implies that the hoist-load barrier
        //       op requires an ordering instruction, which also extends this
        //       requirement to acquire ops (though hoist-store should not need
        //       one if support is added for this later).  However, since no
        //       modern architectures will reorder dependent loads to occur
        //       before the load they depend on (except the Alpha), raw loads
        //       are actually a possible means of ordering specific sequences
        //       of loads in some instances.
        //
        //       For reference, the old behavior (acquire semantics for loads)
        //       required a memory barrier if: ms == msync.seq || isSinkOp!(ms)
        template needsLoadBarrier( msync ms )
        {
            const bool needsLoadBarrier = ms != msync.raw;
        }
        
        
        // NOTE: x86 stores implicitly have release semantics so a memory
        //       barrier is only necessary on acquires.
        template needsStoreBarrier( msync ms )
        {
            const bool needsStoreBarrier = ms == msync.seq ||
                                                 isHoistOp!(ms);
        }
    }


    T atomicLoad(msync ms = msync.seq, T)( ref const shared(T) val )
    {
        static if( T.sizeof == byte.sizeof )
        {
            //////////////////////////////////////////////////////////////////
            // 1 Byte Load
            //////////////////////////////////////////////////////////////////

            static if( needsLoadBarrier!(ms) )
            {
                asm
                {
                    mov DL, 0;
                    mov AL, 0;
                    mov ECX, val;
                    lock; // lock always needed to make this op atomic
                    cmpxchg [ECX], DL;
                }
            }
            else
            {
                asm
                {
                    mov EAX, val;
                    mov AL, [EAX];
                }
            }
        }
        else static if( T.sizeof == short.sizeof )
        {
            //////////////////////////////////////////////////////////////////
            // 2 Byte Load
            //////////////////////////////////////////////////////////////////

            static if( needsLoadBarrier!(ms) )
            {
                asm
                {
                    mov DX, 0;
                    mov AX, 0;
                    mov ECX, val;
                    lock; // lock always needed to make this op atomic
                    cmpxchg [ECX], DX;
                }
            }
            else
            {
                asm
                {
                    mov EAX, val;
                    mov AX, [EAX];
                }
            }
        }
        else static if( T.sizeof == int.sizeof )
        {
            //////////////////////////////////////////////////////////////////
            // 4 Byte Load
            //////////////////////////////////////////////////////////////////

            static if( needsLoadBarrier!(ms) )
            {
                asm
                {
                    mov EDX, 0;
                    mov EAX, 0;
                    mov ECX, val;
                    lock; // lock always needed to make this op atomic
                    cmpxchg [ECX], EDX;
                }
            }
            else
            {
                asm
                {
                    mov EAX, val;
                    mov EAX, [EAX];
                }
            }
        }
        else static if( T.sizeof == long.sizeof && has64BitCAS )
        {
            //////////////////////////////////////////////////////////////////
            // 8 Byte Load on a 32-Bit Processor
            //////////////////////////////////////////////////////////////////

            asm
            {
                push EDI;
                push EBX;
                mov EBX, 0;
                mov ECX, 0;
                mov EAX, 0;
                mov EDX, 0;
                mov EDI, val;
                lock; // lock always needed to make this op atomic
                cmpxch8b [EDI];
                pop EBX;
                pop EDI;
            }
        }
        else
        {
            static assert( false, "Invalid template type specified." );
        }
    }
        
        
    void atomicStore(msync ms = msync.seq, T, V1)( ref shared(T) val, V1 newval )
        if( is( NakedType!(V1) == NakedType!(T) ) )
    {
        static if( T.sizeof == byte.sizeof )
        {
            //////////////////////////////////////////////////////////////////
            // 1 Byte Store
            //////////////////////////////////////////////////////////////////

            static if( needsStoreBarrier!(ms) )
            {
                asm
                {
                    mov EAX, val;
                    mov DL, newval;
                    lock;
                    xchg [EAX], DL;
                }
            }
            else
            {
                asm
                {
                    mov EAX, val;
                    mov DL, newval;
                    mov [EAX], DL;
                }
            }
        }
        else static if( T.sizeof == short.sizeof )
        {
            //////////////////////////////////////////////////////////////////
            // 2 Byte Store
            //////////////////////////////////////////////////////////////////

            static if( needsStoreBarrier!(ms) )
            {
                asm
                {
                    mov EAX, val;
                    mov DX, newval;
                    lock;
                    xchg [EAX], DX;
                }
            }
            else
            {
                asm
                {
                    mov EAX, val;
                    mov DX, newval;
                    mov [EAX], DX;
                }
            }
        }
        else static if( T.sizeof == int.sizeof )
        {
            //////////////////////////////////////////////////////////////////
            // 4 Byte Store
            //////////////////////////////////////////////////////////////////

            static if( needsStoreBarrier!(ms) )
            {
                asm
                {
                    mov EAX, val;
                    mov EDX, newval;
                    lock;
                    xchg [EAX], EDX;
                }
            }
            else
            {
                asm
                {
                    mov EAX, val;
                    mov EDX, newval;
                    mov [EAX], EDX;
                }
            }
        }
        else static if( T.sizeof == long.sizeof && has64BitCAS )
        {
            //////////////////////////////////////////////////////////////////
            // 8 Byte Store on a 32-Bit Processor
            //////////////////////////////////////////////////////////////////
            
            asm
            {
                push EDI;
                push EBX;
                lea EDI, newval;
                mov EBX, [EDI];
                mov ECX, 4[EDI];
                mov EDI, val;
                mov EAX, [EDI];
                mov EDX, 4[EDI];
            L1: lock; // lock always needed to make this op atomic
                cmpxch8b [EDI];
                jne L1;
                pop EBX;
                pop EDI;
            }
        }
        else
        {
            static assert( false, "Invalid template type specified." );
        }
    }
}
else version( AsmX86_64 )
{
    T atomicOp(string op, T, V1)( ref shared(T) val, V1 mod )
        if( is( NakedType!(V1) == NakedType!(T) ) )
    in
    {
        // NOTE: 32 bit x86 systems support 8 byte CAS, which only requires
        //       4 byte alignment, so use size_t as the align type here.
        static if( T.sizeof > size_t.sizeof )
            assert( atomicValueIsProperlyAligned!(size_t)( cast(size_t) &val ) );
        else
            assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
    }
    body
    {
        // binary operators
        //
        // +    -   *   /   %   ^^  &
        // |    ^   <<  >>  >>> ~   in
        // ==   !=  <   <=  >   >=
        static if( op == "+"  || op == "-"  || op == "*"  || op == "/"   ||
                   op == "%"  || op == "^^" || op == "&"  || op == "|"   ||
                   op == "^"  || op == "<<" || op == ">>" || op == ">>>" ||
                   op == "~"  || // skip "in"
                   op == "==" || op == "!=" || op == "<"  || op == "<="  ||
                   op == ">"  || op == ">=" )
        {
            T get = atomicLoad!(msync.raw)( val );
            mixin( "return get " ~ op ~ " mod;" );
        }
        else
        // assignment operators
        //
        // +=   -=  *=  /=  %=  ^^= &=
        // |=   ^=  <<= >>= >>>=    ~=
        static if( op == "+=" || op == "-="  || op == "*="  || op == "/=" ||
                   op == "%=" || op == "^^=" || op == "&="  || op == "|=" ||
                   op == "^=" || op == "<<=" || op == ">>=" || op == ">>>=" ) // skip "~="
        {
            T get, set;

            do
            {
                get = set = atomicLoad!(msync.raw)( val );
                mixin( "set " ~ op ~ " mod;" );
            } while( !cas( &val, get, set ) );
            return set;
        }
        else
        {
            static assert( false, "Operation not supported." );
        }
    }


    bool cas(T,V1,V2)( shared(T)* here, const V1 ifThis, const V2 writeThis )
        if( is( NakedType!(V1) == NakedType!(T) ) &&
            is( NakedType!(V2) == NakedType!(T) ) )
    in
    {
        // NOTE: 32 bit x86 systems support 8 byte CAS, which only requires
        //       4 byte alignment, so use size_t as the align type here.
        static if( T.sizeof > size_t.sizeof )
            assert( atomicValueIsProperlyAligned!(size_t)( cast(size_t) here ) );
        else
            assert( atomicValueIsProperlyAligned!(T)( cast(size_t) here ) );
    }
    body
    {
        static if( T.sizeof == byte.sizeof )
        {
            //////////////////////////////////////////////////////////////////
            // 1 Byte CAS
            //////////////////////////////////////////////////////////////////

            asm
            {
                mov DL, writeThis;
                mov AL, ifThis;
                mov RCX, here;
                lock; // lock always needed to make this op atomic
                cmpxchg [RCX], DL;
                setz AL;
            }
        }
        else static if( T.sizeof == short.sizeof )
        {
            //////////////////////////////////////////////////////////////////
            // 2 Byte CAS
            //////////////////////////////////////////////////////////////////

            asm
            {
                mov DX, writeThis;
                mov AX, ifThis;
                mov RCX, here;
                lock; // lock always needed to make this op atomic
                cmpxchg [RCX], DX;
                setz AL;
            }
        }
        else static if( T.sizeof == int.sizeof )
        {
            //////////////////////////////////////////////////////////////////
            // 4 Byte CAS
            //////////////////////////////////////////////////////////////////

            asm
            {
                mov EDX, writeThis;
                mov EAX, ifThis;
                mov RCX, here;
                lock; // lock always needed to make this op atomic
                cmpxchg [RCX], EDX;
                setz AL;
            }
        }
        else static if( T.sizeof == long.sizeof )
        {
            //////////////////////////////////////////////////////////////////
            // 8 Byte CAS on a 64-Bit Processor
            //////////////////////////////////////////////////////////////////

            asm
            {
                mov RDX, writeThis;
                mov RAX, ifThis;
                mov RCX, here;
                lock; // lock always needed to make this op atomic
                cmpxchg [RCX], RDX;
                setz AL;
            }
        }
        else
        {
            static assert( false, "Invalid template type specified." );
        }
    }


    enum msync
    {
        raw,    /// not sequenced
        acq,    /// hoist-load + hoist-store barrier
        rel,    /// sink-load + sink-store barrier
        seq,    /// fully sequenced (acq + rel)
    }


    private
    {
        template isHoistOp(msync ms)
        {
            enum bool isHoistOp = ms == msync.acq ||
                                  ms == msync.seq;
        }


        template isSinkOp(msync ms)
        {
            enum bool isSinkOp = ms == msync.rel ||
                                 ms == msync.seq;
        }


        // NOTE: While x86 loads have acquire semantics for stores, it appears
        //       that independent loads may be reordered by some processors
        //       (notably the AMD64).  This implies that the hoist-load barrier
        //       op requires an ordering instruction, which also extends this
        //       requirement to acquire ops (though hoist-store should not need
        //       one if support is added for this later).  However, since no
        //       modern architectures will reorder dependent loads to occur
        //       before the load they depend on (except the Alpha), raw loads
        //       are actually a possible means of ordering specific sequences
        //       of loads in some instances.
        //
        //       For reference, the old behavior (acquire semantics for loads)
        //       required a memory barrier if: ms == msync.seq || isSinkOp!(ms)
        template needsLoadBarrier( msync ms )
        {
            const bool needsLoadBarrier = ms != msync.raw;
        }
        
        
        // NOTE: x86 stores implicitly have release semantics so a memory
        //       barrier is only necessary on acquires.
        template needsStoreBarrier( msync ms )
        {
            const bool needsStoreBarrier = ms == msync.seq ||
                                                 isHoistOp!(ms);
        }
    }


    T atomicLoad(msync ms = msync.seq, T)( ref const shared(T) val )
    {
        static if( T.sizeof == byte.sizeof )
        {
            //////////////////////////////////////////////////////////////////
            // 1 Byte Load
            //////////////////////////////////////////////////////////////////

            static if( needsLoadBarrier!(ms) )
            {
                asm
                {
                    mov DL, 0;
                    mov AL, 0;
                    mov RCX, val;
                    lock; // lock always needed to make this op atomic
                    cmpxchg [RCX], DL;
                }
            }
            else
            {
                asm
                {
                    mov RAX, val;
                    mov AL, [RAX];
                }
            }
        }
        else static if( T.sizeof == short.sizeof )
        {
            //////////////////////////////////////////////////////////////////
            // 2 Byte Load
            //////////////////////////////////////////////////////////////////

            static if( needsLoadBarrier!(ms) )
            {
                asm
                {
                    mov DX, 0;
                    mov AX, 0;
                    mov RCX, val;
                    lock; // lock always needed to make this op atomic
                    cmpxchg [RCX], DX;
                }
            }
            else
            {
                asm
                {
                    mov RAX, val;
                    mov AX, [RAX];
                }
            }
        }
        else static if( T.sizeof == int.sizeof )
        {
            //////////////////////////////////////////////////////////////////
            // 4 Byte Load
            //////////////////////////////////////////////////////////////////

            static if( needsLoadBarrier!(ms) )
            {
                asm
                {
                    mov EDX, 0;
                    mov EAX, 0;
                    mov RCX, val;
                    lock; // lock always needed to make this op atomic
                    cmpxchg [RCX], EDX;
                }
            }
            else
            {
                asm
                {
                    mov RAX, val;
                    mov EAX, [RAX];
                }
            }
        }
        else static if( T.sizeof == long.sizeof )
        {
            //////////////////////////////////////////////////////////////////
            // 8 Byte Load
            //////////////////////////////////////////////////////////////////

            static if( needsLoadBarrier!(ms) )
            {
                asm
                {
                    mov RDX, 0;
                    mov RAX, 0;
                    mov RCX, val;
                    lock; // lock always needed to make this op atomic
                    cmpxchg [RCX], RDX;
                }
            }
            else
            {
                asm
                {
                    mov RAX, val;
                    mov RAX, [RAX];
                }
            }
        }
        else
        {
            static assert( false, "Invalid template type specified." );
        }
    }
    
    
    void atomicStore(msync ms = msync.seq, T, V1)( ref shared(T) val, V1 newval )
        if( is( NakedType!(V1) == NakedType!(T) ) )
    {
        static if( T.sizeof == byte.sizeof )
        {
            //////////////////////////////////////////////////////////////////
            // 1 Byte Store
            //////////////////////////////////////////////////////////////////

            static if( needsStoreBarrier!(ms) )
            {
                asm
                {
                    mov RAX, val;
                    mov DL, newval;
                    lock;
                    xchg [RAX], DL;
                }
            }
            else
            {
                asm
                {
                    mov RAX, val;
                    mov DL, newval;
                    mov [RAX], DL;
                }
            }
        }
        else static if( T.sizeof == short.sizeof )
        {
            //////////////////////////////////////////////////////////////////
            // 2 Byte Store
            //////////////////////////////////////////////////////////////////

            static if( needsStoreBarrier!(ms) )
            {
                asm
                {
                    mov RAX, val;
                    mov DX, newval;
                    lock;
                    xchg [RAX], DX;
                }
            }
            else
            {
                asm
                {
                    mov RAX, val;
                    mov DX, newval;
                    mov [RAX], DX;
                }
            }
        }
        else static if( T.sizeof == int.sizeof )
        {
            //////////////////////////////////////////////////////////////////
            // 4 Byte Store
            //////////////////////////////////////////////////////////////////

            static if( needsStoreBarrier!(ms) )
            {
                asm
                {
                    mov RAX, val;
                    mov EDX, newval;
                    lock;
                    xchg [RAX], EDX;
                }
            }
            else
            {
                asm
                {
                    mov RAX, val;
                    mov EDX, newval;
                    mov [RAX], EDX;
                }
            }
        }
        else static if( T.sizeof == long.sizeof && has64BitCAS )
        {
            //////////////////////////////////////////////////////////////////
            // 8 Byte Store on a 64-Bit Processor
            //////////////////////////////////////////////////////////////////
            
            static if( needsStoreBarrier!(ms) )
            {
                asm
                {
                    mov RAX, val;
                    mov RDX, newval;
                    lock;
                    xchg [RAX], RDX;
                }
            }
            else
            {
                asm
                {
                    mov RAX, val;
                    mov RDX, newval;
                    mov [RAX], RDX;
                }
            }
        }
        else
        {
            static assert( false, "Invalid template type specified." );
        }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Unit Tests
////////////////////////////////////////////////////////////////////////////////


version( unittest )
{
    void testCAS(T)( T val = T.init + 1 )
    {
        T         base;
        shared(T) atom;

        assert( base != val );
        assert( atom == base );
        assert( cas( &atom, base, val ) );
        assert( atom == val );
        assert( !cas( &atom, base, base ) );
        assert( atom == val );
    }
    
    
    void testLoadStore(msync ms = msync.seq, T)( T val = T.init + 1 )
    {
        T         base;
        shared(T) atom;
        
        assert( base != val );
        assert( atom == base );
        atomicStore!(ms)( atom, val );
        base = atomicLoad!(ms)( atom );
        assert( base == val );
        assert( atom == val );
    }


    void testType(T)( T val = T.init + 1 )
    {
        testCAS!(T)( val );
        testLoadStore!(msync.seq, T)( val );
        testLoadStore!(msync.raw, T)( val );
    }


    unittest
    {
        testType!(bool)();

        testType!(byte)();
        testType!(ubyte)();

        testType!(short)();
        testType!(ushort)();

        testType!(int)();
        testType!(uint)();

        testType!(shared int*)();

        static if( has64BitCAS )
        {
            testType!(long)();
            testType!(ulong)();
        }

        shared(size_t) i;

        atomicOp!"+="( i, cast(size_t) 1 );
        assert( i == 1 );

        atomicOp!"-="( i, cast(size_t) 1 );
        assert( i == 0 );
    }
}
