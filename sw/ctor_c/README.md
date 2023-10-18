# ctor_c

Test global constructors in C programs.

## Description

This program tests if global constructors are called upon program execution.
To test global destructors (after `main`, before `exit`), goto to the `crt`
directory and define macro `WITH_DESTRUCTORS` in file `startup.c`.

Global constructors in C (not C++) must be functions with the attribute
``constructor``:

```
__attribute__ ((constructor)) void foo(void)
{
    uart1_init(BAUD_RATE, UART_CTRL_NONE);
    uart1_puts("foo\r\n");
}
```

## Status

Works on the board
