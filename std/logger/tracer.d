module std.logger.tracer;

import std.logger.core;

/**
Tracer generates $(D trace) calls to the passed logger wenn the $(D Tracer)
struct gets out of scope, this way tracing the control flow gets easier. The
trace message will contain the linenumber where the $(D Tracer) struct was
created.

Example:
-------
{
    auto tracer = Tracer(trace("entering"));
    ...
            // when the scope is left the tracer will log a trace message
            // saying "leaving scope"
}
-------
*/
struct Tracer {
    private Logger logger;
    private int line;
    private string file;
    private string funcName;
    private string prettyFuncName;

    /**
    This static method is used to construct a Tracer as shown in the above
    example.

    Params:
        l = The $(D Logger) that should be used by the $(D Tracer)

    Returns: A new $(D Tracer)
    */
    static Tracer opCall(Logger l, int line = __LINE__, string file = __FILE__,
           string funcName = __FUNCTION__,
           string prettyFuncName = __PRETTY_FUNCTION__) @trusted
    {
        Tracer ret;
        ret.logger = l;
        ret.line = line;
        ret.file = file;
        ret.funcName = funcName;
        ret.prettyFuncName = prettyFuncName;
        return ret;
    }

    ~this() @trusted
    {
        this.logger.trace("leaving scope", this.line, this.file,
            this.funcName, this.prettyFuncName);
    }
}

unittest
{
    import std.conv;

    auto oldLL = LogManager.globalLogLevel;
    LogManager.globalLogLevel = LogLevel.all;
    scope(exit) LogManager.globalLogLevel = oldLL;
    auto tl = new TestLogger("one", LogLevel.trace);
    tl.trace("hello");
    assert(tl.msg == "hello", tl.msg);
    {
        auto tracer = Tracer(tl.trace("entering"));
        assert(tl.line == __LINE__-1, to!string(tl.line));
    }
    assert(tl.msg != "entering");
    assert(tl.msg == "leaving scope");
    assert(tl.line == __LINE__-5);
}
