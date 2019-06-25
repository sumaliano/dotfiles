import sys
from bs4 import BeautifulSoup as bs

file = sys.argv[1]

with open(file) as f_in:
    soup = bs(f_in, 'html.parser')
    for a in soup.findAll('a'):
        a['href'] += str('.html')

html = soup.prettify("utf-8")
print ('Processing...',file)
with open(file, "wb") as f_out:
    f_out.write(html)
