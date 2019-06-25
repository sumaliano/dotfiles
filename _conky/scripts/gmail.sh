#!/bin/bash

gmail_login="joel42silva@gmail.com"
gmail_password=$1

mail_count="$(wget --secure-protocol=TLSv1 --timeout=3 -t 1 -q -O - \
https://${gmail_login}:${gmail_password}@mail.google.com/mail/feed/atom \
--no-check-certificate | grep 'fullcount' \
| sed -e 's/.*<fullcount>//;s/<\/fullcount>.*//' 2>/dev/null)"

if [ -z "$mail_count" ]; then
echo "Something wrong!"
else
echo "Mail: $mail_count unread."
fi
