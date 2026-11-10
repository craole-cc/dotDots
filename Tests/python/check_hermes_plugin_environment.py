"""Run with the built Hermes venv and its package path: isolated PM acceptance."""
from pathlib import Path
import json
import os
import shutil
import subprocess
import sys
import tempfile

package = Path(sys.argv[1]).resolve()
assert str(package).startswith("/nix/store/")
os.environ["HERMES_INSTALL_ROOT"] = str(package / "share/hermes-agent")
os.environ["HERMES_DISABLE_LAZY_INSTALLS"] = "1"

with tempfile.TemporaryDirectory(prefix="hermes-plugin-environment-") as temporary:
    home = Path(temporary)
    os.environ["HERMES_HOME"] = str(home)
    (home / "config.yaml").write_text("plugins:\n  enabled: []\n  disabled: []\n")
    (home / "cache").mkdir()
    (home / "cache/plugin-catalog.json").write_text(json.dumps({"entries": [], "removed": []}))

    from hermes_cli.plugins_admission import AdmissionRefused, admit_plugin_set_change
    from pm import paths
    from pm.environments import install_state_dir, runtime_facts_path
    from pm.packages import Venv
    from pm.runtime import _resident_runtime
    from hermes_yaml import safe_load

    root = paths.repo_root()
    assert (root / "uv.lock").is_file(), root
    assert (root / "pyproject.toml").is_file(), root
    assert (root / "setup.py").is_file(), root
    assert _resident_runtime() is not None
    assert len(Venv().expected_stamp([], plugin_dirs=[])) == 64
    print("PASS: bundled core metadata and resident PM runtime resolve")

    # Real selection publication crosses the independent PM worker boundary.
    names = {"memory-wiki", "advanced-delegation"}
    for name in names:
        plugin = home / "plugins" / name
        plugin.mkdir(parents=True)
        (plugin / "plugin.yaml").write_text(
            f"name: {name}\nversion: 1.0.0\nrequires_hermes: '>=0.21'\n"
        )
    if len(sys.argv) > 2:
        # An installed plugin tree tests the same declarations as Desktop.
        plugin = home / "plugins/memory-wiki"
        shutil.rmtree(plugin)
        shutil.copytree(sys.argv[2], plugin)

    def select(enabled, disabled=(), **kwargs):
        admit_plugin_set_change(set(enabled), set(disabled),
                                active_plugins_dir=home / "plugins", **kwargs)

    select(names)
    assert set(safe_load((home / "config.yaml").read_text())["plugins"]["enabled"]) == names
    select({"advanced-delegation"}, {"memory-wiki"})
    result = subprocess.run(
        [str(package / "bin/hermes"), "plugins", "enable", "memory-wiki"],
        capture_output=True, text=True, timeout=60,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    assert set(safe_load((home / "config.yaml").read_text())["plugins"]["enabled"]) == names
    assert not runtime_facts_path(root).exists()
    assert not (install_state_dir(root) / "environments").exists()
    assert not (install_state_dir(root) / "publication.json").exists()
    print("PASS: worker selection and CLI re-enable retain the Nix environment")

    before = (home / "config.yaml").read_bytes()
    plugin = home / "plugins/needs-python"
    plugin.mkdir()
    (plugin / "plugin.yaml").write_text(
        "name: needs-python\nversion: 1.0.0\npython_dependencies: [hermes-missing-test-package==0]\n"
    )
    try:
        select(names | {"needs-python"})
    except AdmissionRefused as error:
        assert "Nix-managed environment" in str(error), error
    else:
        raise AssertionError("A Python installation must be declared through Nix")
    assert (home / "config.yaml").read_bytes() == before
    print("PASS: Python dependency changes refuse before publishing configuration")

    # Keep native version and concurrent-edit admission checks intact.
    (plugin / "plugin.yaml").write_text(
        "name: needs-python\nversion: 1.0.0\nrequires_hermes: '>=999.0'\n"
    )
    for options in ({"enabled": names | {"needs-python"}},
                    {"enabled": names, "expected_config": "stale"}):
        try:
            select(**options)
        except AdmissionRefused:
            pass
        else:
            raise AssertionError("Native admission must refuse incompatible or stale selections")
        assert (home / "config.yaml").read_bytes() == before
    print("PASS: version and concurrent-edit refusals preserve configuration")

    # A source checkout still resolves its own metadata, without a Nix-only publication path.
    import pm.paths as source_paths
    from unittest.mock import patch
    source = home / "source"
    (source / "pm/core").mkdir(parents=True)
    (source / "uv.lock").write_text("source fixture")
    with patch.object(source_paths, "__file__", str(source / "pm/paths.py")):
        assert source_paths.repo_root() == source
    print("PASS: checkout root selection is retained")
