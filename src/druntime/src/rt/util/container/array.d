/**
 * Array container for internal usage.
 *
 * Copyright: Copyright Martin Nowak 2013.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Martin Nowak
 */
module rt.util.container.array;

static import common = rt.util.container.common;

struct Array(T)
{
    @disable this(this);

    ~this()
    {
        reset();
    }

    void reset()
    {
        length = 0;
    }

    @property size_t length() const
    {
        return _length;
    }

    @property void length(size_t nlength)
    {
        if (nlength < length)
            foreach (ref val; _ptr[nlength .. length]) common.destroy(val);
        _ptr = cast(T*)common.xrealloc(_ptr, nlength * T.sizeof);
        if (nlength > length)
            foreach (ref val; _ptr[length .. nlength]) common.initialize(val);
        _length = nlength;
    }

    @property bool empty() const
    {
        return !length;
    }

    @property ref inout(T) front() inout
    in { assert(!empty); }
    body
    {
        return _ptr[0];
    }

    @property ref inout(T) back() inout
    in { assert(!empty); }
    body
    {
        return _ptr[_length - 1];
    }

    ref inout(T) opIndex(size_t idx) inout
    in { assert(idx < length); }
    body
    {
        return _ptr[idx];
    }

    inout(T)[] opSlice() inout
    {
        return _ptr[0 .. _length];
    }

    inout(T)[] opSlice(size_t a, size_t b) inout
    in { assert(a < b && b <= length); }
    body
    {
        return _ptr[a .. b];
    }

    alias length opDollar;

    void insertBack()(auto ref T val)
    {
        length = length + 1;
        back = val;
    }

    void popBack()
    {
        length = length - 1;
    }

    void remove(size_t idx)
    in { assert(idx < length); }
    body
    {
        foreach (i; idx .. length - 1)
            _ptr[i] = _ptr[i+1];
        popBack();
    }

    void swap(ref Array other)
    {
        auto ptr = _ptr;
        _ptr = other._ptr;
        other._ptr = ptr;
        immutable len = _length;
        _length = other._length;
        other._length = len;
    }

private:
    T* _ptr;
    size_t _length;
}

unittest
{
    Array!size_t ary;

    assert(ary[] == []);
    ary.insertBack(5);
    assert(ary[] == [5]);
    assert(ary[$-1] == 5);
    ary.popBack();
    assert(ary[] == []);
    ary.insertBack(0);
    ary.insertBack(1);
    assert(ary[] == [0, 1]);
    assert(ary[0 .. 1] == [0]);
    assert(ary[1 .. 2] == [1]);
    assert(ary[$ - 2 .. $] == [0, 1]);
    size_t idx;
    foreach (val; ary) assert(idx++ == val);
    foreach_reverse (val; ary) assert(--idx == val);
    foreach (i, val; ary) assert(i == val);
    foreach_reverse (i, val; ary) assert(i == val);

    ary.insertBack(2);
    ary.remove(1);
    assert(ary[] == [0, 2]);

    assert(!ary.empty);
    ary.reset();
    assert(ary.empty);
    ary.insertBack(0);
    assert(!ary.empty);
    destroy(ary);
    assert(ary.empty);

    // not copyable
    static assert(!__traits(compiles, { Array!size_t ary2 = ary; }));
    Array!size_t ary2;
    static assert(!__traits(compiles, ary = ary2));
    static void foo(Array!size_t copy) {}
    static assert(!__traits(compiles, foo(ary)));

    ary2.insertBack(0);
    assert(ary.empty);
    assert(ary2[] == [0]);
    ary.swap(ary2);
    assert(ary[] == [0]);
    assert(ary2.empty);
}

unittest
{
    alias RC = common.RC;
    Array!RC ary;

    size_t cnt;
    assert(cnt == 0);
    ary.insertBack(RC(&cnt));
    assert(cnt == 1);
    ary.insertBack(ary.front);
    assert(cnt == 2);
    ary.popBack();
    assert(cnt == 1);
    ary.popBack();
    assert(cnt == 0);
}
