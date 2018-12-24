/**
 * Contains the external GC interface.
 *
 * Copyright: Copyright Digital Mars 2005 - 2016.
 * License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   Walter Bright, Sean Kelly
 */

/*          Copyright Digital Mars 2005 - 2016.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module gc.proxy;

import gc.impl.proto.gc;
import gc.config;
import gc.gcinterface;
import gc.registry : createGCInstance;

static import core.memory;

private
{
    static import core.memory;
    alias BlkInfo = core.memory.GC.BlkInfo;

    import core.internal.spinlock;
    static SpinLock instanceLock;

    __gshared bool isInstanceInit = false;
    __gshared GC instance = new ProtoGC();
    __gshared GC proxiedGC; // used to iterate roots of Windows DLLs
}

extern (C)
{
    // do not import GC modules, they might add a dependency to this whole module
    void _d_register_conservative_gc();
    void _d_register_manual_gc();

    // if you don't want to include the default GCs, replace during link by another implementation
    void* register_default_gcs()
    {
        pragma(inline, false);
        // do not call, they register implicitly through pragma(crt_constructor)
        // avoid being optimized away
        auto reg1 = &_d_register_conservative_gc;
        auto reg2 = &_d_register_manual_gc;
        return reg1 < reg2 ? reg1 : reg2;
    }

    void gc_init()
    {
        instanceLock.lock();
        if (!isInstanceInit)
        {
            register_default_gcs();
            config.initialize();
            auto protoInstance = instance;
            auto newInstance = createGCInstance(config.gc);
            if (newInstance is null)
            {
                import core.stdc.stdio : fprintf, stderr;
                import core.stdc.stdlib : exit;

                fprintf(stderr, "No GC was initialized, please recheck the name of the selected GC ('%.*s').\n", cast(int)config.gc.length, config.gc.ptr);
                instanceLock.unlock();
                exit(1);

                // Shouldn't get here.
                assert(0);
            }
            instance = newInstance;
            // Transfer all ranges and roots to the real GC.
            (cast(ProtoGC) protoInstance).term();
            isInstanceInit = true;
        }
        instanceLock.unlock();
    }

    void gc_init_nothrow() nothrow
    {
        scope(failure)
        {
            import core.internal.abort;
            abort("Cannot initialize the garbage collector.\n");
            assert(0);
        }
        gc_init();
    }

    void gc_term()
    {
        if (isInstanceInit)
        {
            switch (config.cleanup)
            {
                default:
                    import core.stdc.stdio : fprintf, stderr;
                    fprintf(stderr, "Unknown GC cleanup method, please recheck ('%.*s').\n",
                            cast(int)config.cleanup.length, config.cleanup.ptr);
                    break;
                case "none":
                    break;
                case "collect":
                    // NOTE: There may be daemons threads still running when this routine is
                    //       called.  If so, cleaning memory out from under then is a good
                    //       way to make them crash horribly.  This probably doesn't matter
                    //       much since the app is supposed to be shutting down anyway, but
                    //       I'm disabling cleanup for now until I can think about it some
                    //       more.
                    //
                    // NOTE: Due to popular demand, this has been re-enabled.  It still has
                    //       the problems mentioned above though, so I guess we'll see.

                    instance.collectNoStack();  // not really a 'collect all' -- still scans
                                                // static data area, roots, and ranges.
                    break;
                case "finalize":
                    instance.runFinalizers((cast(ubyte*)null)[0 .. size_t.max]);
                    break;
            }
            destroy(instance);
        }
    }

    void gc_enable()
    {
        instance.enable();
    }

    void gc_disable()
    {
        instance.disable();
    }

    void gc_collect() nothrow
    {
        instance.collect();
    }

    void gc_minimize() nothrow
    {
        instance.minimize();
    }

    uint gc_getAttr( void* p ) nothrow
    {
        return instance.getAttr(p);
    }

    uint gc_setAttr( void* p, uint a ) nothrow
    {
        return instance.setAttr(p, a);
    }

    uint gc_clrAttr( void* p, uint a ) nothrow
    {
        return instance.clrAttr(p, a);
    }

    void* gc_malloc( size_t sz, uint ba = 0, const TypeInfo ti = null ) nothrow
    {
        return instance.malloc(sz, ba, ti);
    }

    BlkInfo gc_qalloc( size_t sz, uint ba = 0, const TypeInfo ti = null ) nothrow
    {
        return instance.qalloc( sz, ba, ti );
    }

    void* gc_calloc( size_t sz, uint ba = 0, const TypeInfo ti = null ) nothrow
    {
        return instance.calloc( sz, ba, ti );
    }

    void* gc_realloc( void* p, size_t sz, uint ba = 0, const TypeInfo ti = null ) nothrow
    {
        return instance.realloc( p, sz, ba, ti );
    }

    size_t gc_extend( void* p, size_t mx, size_t sz, const TypeInfo ti = null ) nothrow
    {
        return instance.extend( p, mx, sz,ti );
    }

    size_t gc_reserve( size_t sz ) nothrow
    {
        return instance.reserve( sz );
    }

    void gc_free( void* p ) nothrow @nogc
    {
        return instance.free( p );
    }

    void* gc_addrOf( void* p ) nothrow @nogc
    {
        return instance.addrOf( p );
    }

    size_t gc_sizeOf( void* p ) nothrow @nogc
    {
        return instance.sizeOf( p );
    }

    BlkInfo gc_query( void* p ) nothrow
    {
        return instance.query( p );
    }

    core.memory.GC.Stats gc_stats() nothrow
    {
        return instance.stats();
    }

    core.memory.GC.ProfileStats gc_profileStats() nothrow
    {
        return instance.profileStats();
    }

    void gc_addRoot( void* p ) nothrow @nogc
    {
        return instance.addRoot( p );
    }

    void gc_addRange( void* p, size_t sz, const TypeInfo ti = null ) nothrow @nogc
    {
        return instance.addRange( p, sz, ti );
    }

    void gc_removeRoot( void* p ) nothrow
    {
        return instance.removeRoot( p );
    }

    void gc_removeRange( void* p ) nothrow
    {
        return instance.removeRange( p );
    }

    void gc_runFinalizers( in void[] segment ) nothrow
    {
        return instance.runFinalizers( segment );
    }

    bool gc_inFinalizer() nothrow
    {
        return instance.inFinalizer();
    }

    GC gc_getProxy() nothrow
    {
        return instance;
    }

    export
    {
        void gc_setProxy( GC proxy )
        {
            foreach (root; instance.rootIter)
            {
                proxy.addRoot(root);
            }

            foreach (range; instance.rangeIter)
            {
                proxy.addRange(range.pbot, range.ptop - range.pbot, range.ti);
            }

            proxiedGC = instance; // remember initial GC to later remove roots
            instance = proxy;
        }

        void gc_clrProxy()
        {
            foreach (root; proxiedGC.rootIter)
            {
                instance.removeRoot(root);
            }

            foreach (range; proxiedGC.rangeIter)
            {
                instance.removeRange(range);
            }

            instance = proxiedGC;
            proxiedGC = null;
        }
    }
}
