import socket
import sys
import datetime
import base64
import time
from optparse import OptionParser

version=0.2

if __name__ == "__main__":
   usage="NtripClient.py [options] [caster] [port] mountpoint"
   parser=OptionParser(version=version, usage=usage)
   parser.add_option("-u", "--user", type="string", dest="user", default="IBS", help="The Ntripcaster username.  Default: %default")
   (options, args) = parser.parse_args()
   print options.user
   
