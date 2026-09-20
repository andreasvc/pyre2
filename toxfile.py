"""
https://github.com/masenf/tox-ignore-env-name-mismatch

MIT License
Copyright (c) 2023 Masen Furer
"""
from collections.abc import Iterator, Sequence
from contextlib import contextmanager
from typing import Any

from tox.plugin import impl
from tox.tox_env.api import ToxEnv
from tox.tox_env.info import Info
from tox.tox_env.python.virtual_env.runner import VirtualEnvRunner
from tox.tox_env.register import ToxEnvRegister


class FilteredInfo(Info):
    """Subclass of Info that optionally filters specific keys during compare()."""

    def __init__(
        self,
        *args: Any,
        filter_keys: Sequence[str] | None = None,
        filter_section: str | None = None,
        **kwargs: Any,
    ):
        """
        :param filter_keys: key names to pop from value
        :param filter_section: if specified, only pop filter_keys when the compared section matches

        All other args and kwargs are passed to super().__init__
        """
        self.filter_keys = filter_keys
        self.filter_section = filter_section
        super().__init__(*args, **kwargs)

    @contextmanager
    def compare(
        self,
        value: Any,
        section: str,
        sub_section: str | None = None,
    ) -> Iterator[tuple[bool, Any | None]]:
        """Perform comparison and update cached info after filtering `value`."""
        if self.filter_section is None or section == self.filter_section:
            try:
                value = value.copy()
            except AttributeError:  # pragma: no cover
                pass
            else:
                for fkey in self.filter_keys or []:
                    value.pop(fkey, None)
        with super().compare(value, section, sub_section) as rv:
            yield rv


class IgnoreEnvNameMismatchVirtualEnvRunner(VirtualEnvRunner):
    """EnvRunner that does NOT save the env name as part of the cached info."""

    @staticmethod
    def id() -> str:
        return "ignore_env_name_mismatch"

    @property
    def cache(self) -> Info:
        """Return a modified Info class that does NOT pass "name" key to `Info.compare`."""
        return FilteredInfo(
            self.env_dir,
            filter_keys=["name"],
            filter_section=ToxEnv.__name__,
        )


@impl
def tox_register_tox_env(register: ToxEnvRegister) -> None:
    """tox4 entry point: add IgnoreEnvNameMismatchVirtualEnvRunner to registry."""
    register.add_run_env(IgnoreEnvNameMismatchVirtualEnvRunner)
