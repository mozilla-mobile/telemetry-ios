#!/usr/bin/python
import httplib, subprocess

c = httplib.HTTPConnection('169.254.204.191', 8888)
c.request('POST', '/return', '{}')
doc = c.getresponse().read()
print doc
