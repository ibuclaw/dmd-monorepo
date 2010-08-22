/**
 * Contains all implicitly declared types and variables.
 *
 * Copyright: Copyright Digital Mars 2000 - 2010.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Walter Bright, Sean Kelly
 *
 *          Copyright Digital Mars 2000 - 2009.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE_1_0.txt or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module object;

alias typeof(int.sizeof)                    size_t;
alias typeof(cast(void*)0 - cast(void*)0)   ptrdiff_t;
static if (size_t.sizeof == 4)
{
    alias int sizediff_t;
}
else
{
    alias long sizediff_t;
}

alias size_t hash_t;
alias bool equals_t;

alias immutable(char)[]  string;
alias immutable(wchar)[] wstring;
alias immutable(dchar)[] dstring;

class Object
{
    string   toString();
    hash_t   toHash();
    int      opCmp(Object o);
    equals_t opEquals(Object o);
    equals_t opEquals(Object lhs, Object rhs);

    interface Monitor
    {
        void lock();
        void unlock();
    }

    static Object factory(string classname);
}

bool opEquals(Object lhs, Object rhs);
//bool opEquals(TypeInfo lhs, TypeInfo rhs);

void setSameMutex(shared Object ownee, shared Object owner);

struct Interface
{
    TypeInfo_Class   classinfo;
    void*[]     vtbl;
    ptrdiff_t   offset;   // offset to Interface 'this' from Object 'this'
}

struct OffsetTypeInfo
{
    size_t   offset;
    TypeInfo ti;
}

class TypeInfo
{
    hash_t   getHash(in void* p);
    equals_t equals(in void* p1, in void* p2);
    int      compare(in void* p1, in void* p2);
    size_t   tsize();
    void     swap(void* p1, void* p2);
    TypeInfo next();
    void[]   init();
    uint     flags();
    // 1:    // has possible pointers into GC memory
    OffsetTypeInfo[] offTi();
    void destroy(void* p);
    void postblit(void* p);
}

class TypeInfo_Typedef : TypeInfo
{
    TypeInfo base;
    string   name;
    void[]   m_init;
}

class TypeInfo_Enum : TypeInfo_Typedef
{

}

class TypeInfo_Pointer : TypeInfo
{
    TypeInfo m_next;
}

class TypeInfo_Array : TypeInfo
{
    TypeInfo value;
}

class TypeInfo_StaticArray : TypeInfo
{
    TypeInfo value;
    size_t   len;
}

class TypeInfo_AssociativeArray : TypeInfo
{
    TypeInfo value;
    TypeInfo key;
    TypeInfo impl;
}

class TypeInfo_Function : TypeInfo
{
    TypeInfo next;
}

class TypeInfo_Delegate : TypeInfo
{
    TypeInfo next;
}

class TypeInfo_Class : TypeInfo
{
    @property TypeInfo_Class info() { return this; }
    @property TypeInfo typeinfo() { return this; }

    byte[]      init;   // class static initializer
    string      name;   // class name
    void*[]     vtbl;   // virtual function pointer table
    Interface[] interfaces;
    TypeInfo_Class   base;
    void*       destructor;
    void(*classInvariant)(Object);
    uint        m_flags;
    //  1:      // is IUnknown or is derived from IUnknown
    //  2:      // has no possible pointers into GC memory
    //  4:      // has offTi[] member
    //  8:      // has constructors
    // 16:      // has xgetMembers member
    // 32:      // has typeinfo member
    void*       deallocator;
    OffsetTypeInfo[] m_offTi;
    void*       defaultConstructor;
    const(MemberInfo[]) function(string) xgetMembers;

    static TypeInfo_Class find(in char[] classname);
    Object create();
    const(MemberInfo[]) getMembers(in char[] classname);
}

alias TypeInfo_Class ClassInfo;

class TypeInfo_Interface : TypeInfo
{
    ClassInfo info;
}

class TypeInfo_Struct : TypeInfo
{
    string name;
    void[] m_init;

    uint function(in void*)               xtoHash;
    equals_t function(in void*, in void*) xopEquals;
    int function(in void*, in void*)      xopCmp;
    string function(in void*)             xtoString;

    uint m_flags;

    const(MemberInfo[]) function(in char[]) xgetMembers;
    void function(void*)                    xdtor;
    void function(void*)                    xpostblit;
}

class TypeInfo_Tuple : TypeInfo
{
    TypeInfo[]  elements;
}

class TypeInfo_Const : TypeInfo
{
    TypeInfo next;
}

class TypeInfo_Invariant : TypeInfo_Const
{

}

class TypeInfo_Shared : TypeInfo_Const
{
}

class TypeInfo_Inout : TypeInfo_Const
{
}

abstract class MemberInfo
{
    string name();
}

class MemberInfo_field : MemberInfo
{
    this(string name, TypeInfo ti, size_t offset);

    override string name();
    TypeInfo typeInfo();
    size_t offset();
}

class MemberInfo_function : MemberInfo
{
    enum
    {
        Virtual = 1,
        Member  = 2,
        Static  = 4,
    }

    this(string name, TypeInfo ti, void* fp, uint flags);

    override string name();
    TypeInfo typeInfo();
    void* fp();
    uint flags();
}

struct ModuleInfo
{
    struct New
    {
	    uint flags;
    	uint index;
    }

    struct Old
    {
	    string           name;
	    ModuleInfo*[]    importedModules;
	    TypeInfo_Class[] localClasses;
	    uint             flags;

	    void function() ctor;
	    void function() dtor;
	    void function() unitTest;
	    void* xgetMembers;
	    void function() ictor;
	    void function() tlsctor;
	    void function() tlsdtor;
	    uint index;
	    void*[1] reserved;
    }

    union
    {
	    New n;
	    Old o;
    }

    @property bool isNew();
    @property uint index();
    @property void index(uint i);
    @property uint flags();
    @property void flags(uint f);
    @property void function() tlsctor();
    @property void function() tlsdtor();
    @property void* xgetMembers();
    @property void function() ctor();
    @property void function() dtor();
    @property void function() ictor();
    @property void function() unitTest();
    @property ModuleInfo*[] importedModules();
    @property TypeInfo_Class[] localClasses();
    @property string name();

    static int opApply(scope int delegate(ref ModuleInfo*) dg);
}

ModuleInfo*[] _moduleinfo_tlsdtors;
uint          _moduleinfo_tlsdtors_i;

extern (C) void _moduleTlsCtor();
extern (C) void _moduleTlsDtor();

class Throwable : Object
{
    interface TraceInfo
    {
        int opApply(scope int delegate(ref char[]));
        string toString();
    }

    string      msg;
    string      file;
    size_t      line;
    TraceInfo   info;
    Throwable   next;

    this(string msg, Throwable next = null);
    this(string msg, string file, size_t line, Throwable next = null);
    override string toString();
}


class Exception : Throwable
{
    this(string msg, Throwable next = null);
    this(string msg, string file, size_t line, Throwable next = null);
}


class Error : Throwable
{
    this(string msg, Throwable next = null);
    this(string msg, string file, size_t line, Throwable next = null);
}

extern (C)
{
    // from druntime/src/compiler/dmd/aaA.d

    size_t _aaLen(void* p);
    void*  _aaGet(void** pp, TypeInfo keyti, size_t valuesize, ...);
    void*  _aaGetRvalue(void* p, TypeInfo keyti, size_t valuesize, ...);
    void*  _aaIn(void* p, TypeInfo keyti);
    void   _aaDel(void* p, TypeInfo keyti, ...);
    void[] _aaValues(void* p, size_t keysize, size_t valuesize);
    void[] _aaKeys(void* p, size_t keysize, size_t valuesize);
    void*  _aaRehash(void** pp, TypeInfo keyti);

    extern (D) typedef scope int delegate(void *) _dg_t;
    int _aaApply(void* aa, size_t keysize, _dg_t dg);

    extern (D) typedef scope int delegate(void *, void *) _dg2_t;
    int _aaApply2(void* aa, size_t keysize, _dg2_t dg);

    void* _d_assocarrayliteralT(TypeInfo_AssociativeArray ti, size_t length, ...);
}

struct AssociativeArray(Key, Value)
{
    void* p;

    size_t aligntsize(size_t tsize)
    {
	// Is pointer alignment on the x64 4 bytes or 8?
	return (tsize + size_t.sizeof - 1) & ~(size_t.sizeof - 1);
    }

    size_t length() @property { return _aaLen(p); }

    Value[Key] rehash() @property
    {
        auto p = _aaRehash(&p, typeid(Value[Key]));
        return *cast(Value[Key]*)(&p);
    }

    Value[] values() @property
    {
        auto a = _aaValues(p, aligntsize(Key.sizeof), Value.sizeof);
        return *cast(Value[]*) &a;
    }

    Key[] keys() @property
    {
        auto a = _aaKeys(p, aligntsize(Key.sizeof), Value.sizeof);
        return *cast(Key[]*) &a;
    }

    int opApply(scope int delegate(ref Key, ref Value) dg)
    {
        return _aaApply2(p, aligntsize(Key.sizeof), cast(_dg2_t)dg);
    }

    int opApply(scope int delegate(ref Value) dg)
    {
        return _aaApply(p, aligntsize(Key.sizeof), cast(_dg_t)dg);
    }

    int delegate(int delegate(ref Key) dg) byKey()
    {
	int foo(int delegate(ref Key) dg)
	{
	    int byKeydg(ref Key key, ref Value value)
	    {
		return dg(key);
	    }

	    return _aaApply2(p, aligntsize(Key.sizeof), cast(_dg2_t)&byKeydg);
	}

	return &foo;
    }

    int delegate(int delegate(ref Value) dg) byValue()
    {
	return &opApply;
    }

    Value get(Key key, lazy Value defaultValue)
    {
	auto p = key in *cast(Value[Key]*)(&p);
	return p ? *p : defaultValue;
    }
}

void clear(T)(T obj) if (is(T == class))
{
    auto ci = obj.classinfo;
    auto defaultCtor =
        cast(void function(Object)) ci.defaultConstructor;
    version(none) // enforce isn't available in druntime
        _enforce(defaultCtor || (ci.flags & 8) == 0);
    immutable size = ci.init.length;

    auto ci2 = ci;
    do
    {
        auto dtor = cast(void function(Object))ci2.destructor;
        if (dtor)
            dtor(obj);
        ci2 = ci2.base;
    } while (ci2)

    auto buf = (cast(void*) obj)[0 .. size];
    buf[] = ci.init;
    if (defaultCtor)
        defaultCtor(obj);
}

void clear(T)(ref T obj) if (is(T == struct))
{
    static if (is(typeof(obj.__dtor())))
    {
        obj.__dtor();
    }
    auto buf = (cast(void*) &obj)[0 .. T.sizeof];
    // @@@BUG4436@@@ workaround
    //auto init = (cast(void*) &T.init)[0 .. T.sizeof];
    static T empty;
    auto init = (cast(void*) &empty)[0 .. T.sizeof];
    buf[] = init[];
}

void clear(T : U[n], U, size_t n)(ref T obj)
{
    obj = T.init;
}

void clear(T)(ref T obj)
    if (!is(T == struct) && !is(T == class) && !_isStaticArray!T)
{
    obj = T.init;
}

template _isStaticArray(T : U[N], U, size_t N)
{
    enum bool _isStaticArray = true;
}

template _isStaticArray(T)
{
    enum bool _isStaticArray = false;
}

private
{
    extern (C) void _d_arrayshrinkfit(TypeInfo ti, void[] arr);
    extern (C) size_t _d_arraysetcapacity(TypeInfo ti, size_t newcapacity, void *arrptr);
}

@property size_t capacity(T)(T[] arr)
{
    return _d_arraysetcapacity(typeid(T[]), 0, cast(void *)&arr);
}

size_t reserve(T)(ref T[] arr, size_t newcapacity)
{
    return _d_arraysetcapacity(typeid(T[]), newcapacity, cast(void *)&arr);
}

void assumeSafeAppend(T)(T[] arr)
{
    _d_arrayshrinkfit(typeid(T[]), *(cast(void[]*)&arr));
}

bool _ArrayEq(T1, T2)(T1[] a1, T2[] a2)
{
    if (a1.length != a2.length)
	return false;
    foreach(i, a; a1)
    {	if (a != a2[i])
	    return false;
    }
    return true;
}

