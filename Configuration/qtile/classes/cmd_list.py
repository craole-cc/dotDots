class Command:

    _command = []

    def __init__(self):
        self._command = None
        self.reset_default_values()

    def reset_default_values(self):
        self._command = Command._command

    @property
    def command(self):
        # | Convert dictionary valurs to a list
        if isinstance(self._command, dict):
            return list(self._command.keys())

        # | Convert literal string to a list
        elif isinstance(self._command, str):
            if "," in self._command:
                return self._command.split(",")
            else:
                return self._command.split()

        # | Put other iterable items in a list
        else:
            return self._command

    @command.setter
    def command(self, value):
        self._command = value

    def __iter__(self):
        return iter([self.command])

    # cmd = Command()
    # print(cmd.command)

    # cmd.command = 42
    # print(cmd.command)"bat"

    # cmd.reset_default_values()
    # print(cmd.command)
