#include <iostream>
#include <csignal>
#include <unistd.h>
#include <execinfo.h>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "SMU.h"
#include <cxxabi.h>
#include <string>

using namespace std;

void signalHandler( int signum )
{
    string bktrace_buf;
    void *array[20];
    char bktrace_line[1024];
    size_t size;

    cout << "Interrupt signal (" << signum << ") received.\n";

    size = backtrace(array, 16);
    if (size == 0) {
          printf("  <empty, possibly corrupt>\n");
          return;
    }
    
    // Code is based from an on-line example at:
    // Timo Bingmann from http://idlebox.net/
    // http://panthema.net/2008/0901-stacktrace-demangled/
    // which was published under the WTFPL v2.0
    char **symbollist = backtrace_symbols(array, size);

    // allocate string which will be filled with the demangled function name
    // malloc in signal handlers are poor form - but there isn't much we can do.
    size_t funcnamesize = 256;
    char* funcname = (char*)malloc(funcnamesize);

    // iterate over the returned symbol lines. skip the first, it is the
    // address of this function.
    for (size_t i = 1; i < size; i++) {
        char *begin_name = 0, *begin_offset = 0, *end_offset = 0;

        // find parentheses and +address offset surrounding the mangled name:
        // ./module(function+0x15c) [0x8048a6d]
        for (char *p = symbollist[i]; *p; ++p)
        {
            if (*p == '(')
            begin_name = p;
            else if (*p == '+')
            begin_offset = p;
            else if (*p == ')' && begin_offset) {
            end_offset = p;
            break;
            }
        }

        if (begin_name && begin_offset && end_offset
        && begin_name < begin_offset) {
            *begin_name++ = '\0';
            *begin_offset++ = '\0';
            *end_offset = '\0';

            // mangled name is now in [begin_name, begin_offset) and caller
            // offset in [begin_offset, end_offset). now apply
            // __cxa_demangle():

            int status;
            char* ret = abi::__cxa_demangle(begin_name,
                            funcname, &funcnamesize, &status);
            if (status == 0) {
                funcname = ret; // use possibly realloc()-ed string
                snprintf(bktrace_line, sizeof(bktrace_line), "  %s : %s+%s\n",
                    symbollist[i], funcname, begin_offset);
                bktrace_buf.append(bktrace_line);
            } else {
                // demangling failed. Output function name as a C function with
                // no arguments.
                snprintf(bktrace_line, sizeof(bktrace_line), "  %s : %s()+%s\n",
                    symbollist[i], begin_name, begin_offset);
                bktrace_buf.append(bktrace_line);
            }
        } else {
            // couldn't parse the line? print the whole line.
            snprintf(bktrace_line, sizeof(bktrace_line), "  %s\n",
                     symbollist[i]);
            bktrace_buf.append(bktrace_line);
        }
    }

    free(funcname);
    free(symbollist);
    
    cout << bktrace_buf;
    
    exit(signum);
}



int main(int argc, char *argv[])
{

    signal(SIGUSR1, signalHandler);
    signal(SIGSEGV, signalHandler);

    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    registerTypes();

    SessionItem smu_session;
    smu_session.openAllDevices();
    engine.rootContext()->setContextProperty("session", &smu_session);

    if (argc > 1) {
        if (strcmp(argv[1], "-v") || strcmp(argv[1], "--version")) {
            std::cout << GIT_VERSION << ": Built on " << BUILD_DATE << std::endl;
            return 0;
        }
        engine.load(argv[1]);
    } else {
        engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
    }

    int r = app.exec();

    smu_session.closeAllDevices();

    return r;
}
