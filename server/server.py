#!/usr/local/bin/python2

import subprocess
from bottle import run, post, request, response, get, route

@route('/<path>',method = 'POST')
def process(path):
    return subprocess.check_output(['python2',path+'.py'],shell=True)

run(host='localhost', port=8080, debug=False)
