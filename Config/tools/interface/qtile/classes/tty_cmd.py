from functions.wehave import wehave, wehave_location


class TTY_cmd:
    _classopts = {
        "~[EMULATOR]~": "~[CLASSOPT]~",
        "kitty": "--class",
        "alacritty": "--class",
        "st": "-c",
        "xterm": "-class",
        "termite": "",
        "urxvt": "",
        "terminator": "",
        "guake": "",
        "tilix": "",
        "guake": "",
    }
    _emulator = wehave(_classopts)
    # _classopt = _classopts.get(_emulator)
    _classopt = []
    _classname = []
    _command = []

    def __init__(self):
        self.emulator = None
        self.classopt = None
        self.classname = None
        self.command = None
        self.reset()

    def reset(self):
        self.emulator = TTY_cmd._emulator
        # self.classopt = TTY_cmd._classopts.get("alacritty")
        self.classopt = TTY_cmd._classopt
        self.classname = TTY_cmd._classname
        self.command = TTY_cmd._command

    # | Terminal
    @property
    def emulator(self):
        if wehave(self._emulator):
            return self._emulator

        # | Select an available emulator from the list
        elif wehave(self._classopts):
            return wehave(self._classopts)

        # else:
        #     raise ValueError("Terminal emulator missing.")

    @emulator.setter
    def emulator(self, value):
        self._emulator = value

    # | ClassOption
    @property
    def classopt(self):
        if isinstance(self._classopt, str):
            return self._classopt
        elif self.emulator in self._classopts:
            return self._classopts.get(self.emulator)

    @classopt.setter
    def classopt(self, value):
        self._classopt = value

    # | ClassName
    @property
    def classname(self):
        if self._classname:
            return self._classname

    @classname.setter
    def classname(self, value):
        self._classname = value

    # | Command
    @property
    def command(self):
        return self._command

    @command.setter
    def command(self, value):
        self._command = value

    def __str__(self):
        emulator = self.emulator
        classopt = self.classopt
        classname = self.classname
        command = self.command

        if not command:
            raise ValueError("command not given")
        elif not emulator:
            raise ValueError("emulator not set")
        elif not classopt:
            return f"{emulator} -e {command}"
        elif classopt and not classname:
            return f'{emulator} -e {classopt} "{command}" {command}'
        else:
            return f'\'{emulator} -e {classopt} "{classname}" {command}\''
