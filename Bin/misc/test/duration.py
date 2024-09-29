#!/usr/bin/env python3

import os

inputSeconds = $*
days, remainder = divmod($*, (60*60*24))
hours, remainder = divmod(remainder, (60*60))
minutes, seconds = divmod(remainder, 60)
print ('%d:%d:%d' % (days, hours, minutes))