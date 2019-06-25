PREFIX=/usr

x11_bsd_flags = -I/usr/X11R6/include -L/usr/X11R6/lib

all:
	${CC} ${CFLAGS} ${LDFLAGS} clipnotify.c -o clipnotify $(x11_bsd_flags) -lX11 -lXfixes

install:
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp -f clipmenud $(DESTDIR)$(PREFIX)/bin/clipmenud
	cp -f clipmenu $(DESTDIR)$(PREFIX)/bin/clipmenu
	cp -f clipdel $(DESTDIR)$(PREFIX)/bin/clipdel
	cp -f clipnotify $(DESTDIR)$(PREFIX)/bin/clipnotify

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/clipmenud
	rm -f $(DESTDIR)$(PREFIX)/bin/clipmenu
	rm -f $(DESTDIR)$(PREFIX)/bin/clipdel
	rm -f $(DESTDIR)$(PREFIX)/bin/clipnotify
