module std.logger.multilogger;

import std.logger.core;
import std.logger.stdiologger;

/** MultiLogger logs to multiple logger.

It can be used to construct arbitrary, tree like structures. Basically a $(D
MultiLogger) is a map. It maps $(D string)s to $(D Logger). By adding $(D
MultiLogger) into another $(D MultiLogger) non leaf nodes are added. The
*/
class MultiLogger : Logger
{
    /** Default constructor for the $(D MultiLogger) Logger.

    Params:
      lv = The $(D LogLevel) for the $(D MultiLogger). By default the $(D LogLevel)
      for $(D MultiLogger) is $(D LogLevel.info).

    Example:
    -------------
    auto l1 = new MultiLogger;
    auto l2 = new MultiLogger(LogLevel.fatal);
    -------------
    */
    public this(const LogLevel lv = LogLevel.info) @safe
    {
        super("", lv);
    }

    /** A constructor for the $(D MultiLogger) Logger.

    Params:
      name = The name of the logger. Compare to $(D FileLogger.insertLogger).
      lv = The $(D LogLevel) for the $(D MultiLogger). By default the $(D LogLevel)
      for $(D MultiLogger) is $(D LogLevel.info).

    Example:
    -------------
    auto l1 = new MultiLogger("loggerName");
    auto l2 = new MultiLogger("loggerName", LogLevel.fatal);
    -------------
    */
    public this(string name, const LogLevel lv = LogLevel.info) @safe
    {
        super(name, lv);
    }

    private Logger[string] logger;

    /** This method inserts a new Logger into the Multilogger.
    */
    public void insertLogger(Logger newLogger) @safe
    {
        if (newLogger.name.empty)
        {
            throw new Exception("A Logger must have a name to be inserted " ~
                "into the MulitLogger");
        }
        else if (newLogger.name in logger)
        {
            throw new Exception(
                "This MultiLogger instance already holds a  Logger named '" ~
                   newLogger.name ~ "'");
        }
        else
        {
            logger[newLogger.name] = newLogger;
        }
    }

    ///
    unittest
    {
        auto l1 = new MultiLogger;
        auto l2 = new StdIOLogger("some_logger");

        l1.insertLogger(l2);

        assert(l1.removeLogger("some_logger") is l2);
    }

    /** This method removes a Logger from the Multilogger.

    See_Also: std.logger.MultiLogger.insertLogger
    */
    public Logger removeLogger(string loggerName) @safe
    {
        if (loggerName !in logger)
        {
            throw new Exception(
                "This MultiLogger instance does not hold a Logger named '" ~
                loggerName ~ "'");
        }
        else
        {
            Logger ret = logger[loggerName];
            logger.remove(loggerName);
            return ret;
        }
    }

    /** This method returns a $(D Logger) if it is present in the $(D
    MultiLogger), otherwise a $(D RangeError) will be thrown.
    */
    public Logger opIndex(string key) @safe
    {
        return logger[key];
    }

    ///
    unittest
    {
        auto ml = new MultiLogger();
        auto sl = new StdIOLogger("some_name");

        ml.insertLogger(sl);

        assert(ml["some_name"] is sl);
    }

    public override void writeLogMsg(ref LoggerPayload payload) @trusted {
        version(DisableMultiLogging)
        {
        }
        else
        {
            foreach (it; logger)
            {
                /* The LogLevel of the Logger must be >= than the LogLevel of
                the payload. Usally this is handled by the log functions. As
                they are not called in this case, we have to handle it by hand
                here.
                */
                const bool ll = payload.logLevel >= it.logLevel;
                if (ll)
                {
                    it.writeLogMsg(payload);
                }
            }
        }
    }
}
