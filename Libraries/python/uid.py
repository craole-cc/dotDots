#!/usr/bin/env python3
import os
import secrets
from datetime import datetime

time_str = datetime.now().astimezone().strftime("%Y%m%d%H%M%S")
pid = os.getpid()
ppid = getattr(os, "getppid", lambda: 0)()
rand_hex = secrets.token_hex(4)

print(f"{time_str}_{pid:05d}_{ppid:05d}_{rand_hex}")
