/**
 * The config module contains utility routines and configuration information
 * specific to this package.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2009.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Sean Kelly
 * Source:    $(DRUNTIMESRC core/sync/_config.d)
 */

/*          Copyright Sean Kelly 2005 - 2009.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE_1_0.txt or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module core.sync.config;


version( Posix )
{
    private import core.sys.posix.time;
    private import core.sys.posix.sys.time;
    private import core.time;
    
    
    void mktspec( ref timespec t )
    {
        static if( false && is( typeof( clock_gettime ) ) )
        {
            clock_gettime( CLOCK_REALTIME, &t );
        }
        else
        {
            timeval tv;

            gettimeofday( &tv, null );
            (cast(byte*) &t)[0 .. t.sizeof] = 0;
            t.tv_sec  = cast(typeof(t.tv_sec))  tv.tv_sec;
            t.tv_nsec = cast(typeof(t.tv_nsec)) tv.tv_usec * 1_000;
        }
    }


    void mktspec( ref timespec t, Duration delta )
    {
        mktspec( t );
        mvtspec( t, delta );
    }


    void mvtspec( ref timespec t, Duration delta )
    {
        enum : uint
        {
            NANOS_PER_SECOND = 1000_000_000
        }

        auto val  = delta;
             val += seconds( cast(Duration.SecType) t.tv_sec );
             val += nanoseconds( cast(Duration.FracType) t.tv_nsec );
        //auto val = delta + seconds( cast(Duration.SecType) t.tv_sec ) +
        //                 + nanoseconds( cast(Duration.FracType) t.tv_nsec );
        
        if( val.totalSeconds > t.tv_sec.max )
        {
            t.tv_sec  = t.tv_sec.max;
            t.tv_nsec = cast(typeof(t.tv_nsec)) (val.totalNanoseconds % NANOS_PER_SECOND);
        }
        else
        {
            t.tv_sec  = cast(typeof(t.tv_sec)) val.totalSeconds;
            t.tv_nsec = cast(typeof(t.tv_nsec)) (val.totalNanoseconds % NANOS_PER_SECOND);
        }
    }
}
