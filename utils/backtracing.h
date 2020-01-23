#ifndef __BACKTRACING__H_
#define __BACKTRACING__H_

#ifdef _WIN32
    #include <windows.h>
    #include <imagehlp.h>
    #include <dbghelp.h>
	#include <conio.h>
#else
    #include <iostream>
    #include <string>
    #include <csignal>
    #include <unistd.h>
    #include <execinfo.h>
    #include <cxxabi.h>

    using namespace std;
#endif

static char *glbProgramName;

#ifdef _BUILD_STACKTRACE
#ifdef _WIN32

void windows_print_stacktrace(CONTEXT* context)
{
    int addr2line_available = 0;
    char system_cmd[1024];
    DWORD machine_type;

    printf("Checking for \"addr2line\" utility:\n");
    if (system("addr2line -v") == 0)
        addr2line_available = 1;

    SymInitialize(GetCurrentProcess(), 0, TRUE);

    STACKFRAME frame;

    memset(&frame, 0, sizeof(STACKFRAME));

//    frame.AddrPC.Offset         = context->Eip;
    frame.AddrPC.Mode           = AddrModeFlat;
//    frame.AddrStack.Offset      = context->Esp;
    frame.AddrStack.Mode        = AddrModeFlat;
//    frame.AddrFrame.Offset      = context->Ebp;
    frame.AddrFrame.Mode        = AddrModeFlat;


#ifdef _M_X64
	    frame.AddrPC.Offset = context->Rip;
	    frame.AddrFrame.Offset = context->Rbp;
	    frame.AddrStack.Offset = context->Rsp;
	    machine_type = IMAGE_FILE_MACHINE_AMD64;
#else
	    frame.AddrPC.Offset = context->Eip;
	    frame.AddrPC.Offset = context->Ebp;
	    frame.AddrPC.Offset = context->Esp;
	    machine_type = IMAGE_FILE_MACHINE_I386;
#endif

    static char symbolBuffer[sizeof(IMAGEHLP_SYMBOL) + 255];
    memset(symbolBuffer, 0, sizeof(IMAGEHLP_SYMBOL) + 255);

    IMAGEHLP_SYMBOL *symbol = (IMAGEHLP_SYMBOL*) symbolBuffer;
    symbol->SizeOfStruct    = sizeof(IMAGEHLP_SYMBOL) + 255;
    symbol->MaxNameLength   = 254;

    IMAGEHLP_LINE line;
    memset(&line, 0, sizeof(IMAGEHLP_LINE));
    line.SizeOfStruct = sizeof(IMAGEHLP_LINE);

    IMAGEHLP_MODULE module;
    memset(&module, 0, sizeof(IMAGEHLP_MODULE));
    module.SizeOfStruct = sizeof(IMAGEHLP_MODULE);

    printf("\nBacktrace:\n");
    while (StackWalk(machine_type,
           GetCurrentProcess(),
           GetCurrentThread(),
           &frame,
           context,
           0,
           SymFunctionTableAccess,
           SymGetModuleBase,
           0 ) )
    {
        DWORD displacement = 0;

        if (SymGetModuleInfo(GetCurrentProcess(), frame.AddrPC.Offset,
                &module))
        {
            printf("%s: ", module.ModuleName);
        }

        if (SymGetLineFromAddr(GetCurrentProcess(), frame.AddrPC.Offset,
                &displacement, &line))
        {
            printf("%s (line:%lu): ", line.FileName, line.LineNumber);
        }

        if (SymGetSymFromAddr(GetCurrentProcess(), frame.AddrPC.Offset,
                &displacement, symbol))
        {
            printf("FrameAddr: 0x%lX symbol: %s\n", frame.AddrPC.Offset,
                    symbol->Name);
        }
        else
        {
            printf("FrameAddr: 0x%lX\n", frame.AddrPC.Offset);
        }

        if (addr2line_available)
        {
            snprintf(system_cmd, sizeof(system_cmd),
                "addr2line -f -p -s -a -e %s 0x%lX", glbProgramName, frame.AddrPC.Offset);
            system(system_cmd);
        }
    }

    SymCleanup(GetCurrentProcess());
}

/* Code from
 * http://spin.atomicobject.com/2013/01/13/exceptions-stack-traces-c/
 */

LONG WINAPI windows_exception_handler(EXCEPTION_POINTERS * ExceptionInfo)
{
  switch(ExceptionInfo->ExceptionRecord->ExceptionCode)
  {
    case EXCEPTION_ACCESS_VIOLATION:
      fputs("Error: EXCEPTION_ACCESS_VIOLATION\n", stderr);
      break;
    case EXCEPTION_ARRAY_BOUNDS_EXCEEDED:
      fputs("Error: EXCEPTION_ARRAY_BOUNDS_EXCEEDED\n", stderr);
      break;
    case EXCEPTION_BREAKPOINT:
      fputs("Error: EXCEPTION_BREAKPOINT\n", stderr);
      break;
    case EXCEPTION_DATATYPE_MISALIGNMENT:
      fputs("Error: EXCEPTION_DATATYPE_MISALIGNMENT\n", stderr);
      break;
    case EXCEPTION_FLT_DENORMAL_OPERAND:
      fputs("Error: EXCEPTION_FLT_DENORMAL_OPERAND\n", stderr);
      break;
    case EXCEPTION_FLT_DIVIDE_BY_ZERO:
      fputs("Error: EXCEPTION_FLT_DIVIDE_BY_ZERO\n", stderr);
      break;
    case EXCEPTION_FLT_INEXACT_RESULT:
      fputs("Error: EXCEPTION_FLT_INEXACT_RESULT\n", stderr);
      break;
    case EXCEPTION_FLT_INVALID_OPERATION:
      fputs("Error: EXCEPTION_FLT_INVALID_OPERATION\n", stderr);
      break;
    case EXCEPTION_FLT_OVERFLOW:
      fputs("Error: EXCEPTION_FLT_OVERFLOW\n", stderr);
      break;
    case EXCEPTION_FLT_STACK_CHECK:
      fputs("Error: EXCEPTION_FLT_STACK_CHECK\n", stderr);
      break;
    case EXCEPTION_FLT_UNDERFLOW:
      fputs("Error: EXCEPTION_FLT_UNDERFLOW\n", stderr);
      break;
    case EXCEPTION_ILLEGAL_INSTRUCTION:
      fputs("Error: EXCEPTION_ILLEGAL_INSTRUCTION\n", stderr);
      break;
    case EXCEPTION_IN_PAGE_ERROR:
      fputs("Error: EXCEPTION_IN_PAGE_ERROR\n", stderr);
      break;
    case EXCEPTION_INT_DIVIDE_BY_ZERO:
      fputs("Error: EXCEPTION_INT_DIVIDE_BY_ZERO\n", stderr);
      break;
    case EXCEPTION_INT_OVERFLOW:
      fputs("Error: EXCEPTION_INT_OVERFLOW\n", stderr);
      break;
    case EXCEPTION_INVALID_DISPOSITION:
      fputs("Error: EXCEPTION_INVALID_DISPOSITION\n", stderr);
      break;
    case EXCEPTION_NONCONTINUABLE_EXCEPTION:
      fputs("Error: EXCEPTION_NONCONTINUABLE_EXCEPTION\n", stderr);
      break;
    case EXCEPTION_PRIV_INSTRUCTION:
      fputs("Error: EXCEPTION_PRIV_INSTRUCTION\n", stderr);
      break;
    case EXCEPTION_SINGLE_STEP:
      fputs("Error: EXCEPTION_SINGLE_STEP\n", stderr);
      break;
    case EXCEPTION_STACK_OVERFLOW:
      fputs("Error: EXCEPTION_STACK_OVERFLOW\n", stderr);
      break;
    default:
      fputs("Error: Unrecognized Exception\n", stderr);
      break;
  }
  fflush(stderr);
  /* If this is a stack overflow then we can't walk the stack, so just show
    where the error happened */
  if (EXCEPTION_STACK_OVERFLOW != ExceptionInfo->ExceptionRecord->ExceptionCode)
  {
      windows_print_stacktrace(ExceptionInfo->ContextRecord);
  }
  else
  {
      printf("Stack Overflow!\n");
  }

  printf("Press 'q' to close.");
  while (!_kbhit()) {
    if (_getch() == 'q')
      break;
  }

  return EXCEPTION_EXECUTE_HANDLER;
}

BOOL WINAPI consoleHandler(DWORD dwCtrlType)
{
    CONTEXT context;
    if (dwCtrlType == CTRL_C_EVENT) {
        RtlCaptureContext(&context);
        windows_print_stacktrace(&context);
		printf("Press 'q' to close.");
        while (!_kbhit()) {
            if (_getch() == 'q')
                break;
        }
    }

    return FALSE;
}

#else
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

    cout << "Call Stack:\n" << bktrace_buf;

    exit(signum);
}

#endif

void init_signal_handlers(char *program_name)
{
    glbProgramName = program_name;
#if _WIN32
    SetUnhandledExceptionFilter(windows_exception_handler);
    if (!SetConsoleCtrlHandler(consoleHandler, TRUE)) {
        printf("Could not add handler to console");
    }
#else
    signal(SIGUSR1, signalHandler);
    signal(SIGSEGV, signalHandler);
#endif
}


#endif
#endif /* __BACKTRACING__H_ */
