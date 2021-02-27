#include <X11/extensions/scrnsaver.h>
#include <stdio.h>

int main(void) {
    Display *display = XOpenDisplay(NULL);

    if (display == NULL)
    {
        return(-1);
    }

    static XScreenSaverInfo *info;
    info = XScreenSaverAllocInfo();

    int screen = DefaultScreen(display);

    XScreenSaverQueryInfo(display, RootWindow(display,screen), info);

    printf("%d\n", info->idle/1000);

    return(0);
}
