"""
Tests for pynhschooldata Python wrapper.

Minimal smoke tests - the actual data logic is tested by R testthat.
These just verify the Python wrapper imports and exposes expected functions.
"""

import pytest


def test_import_package():
    """Package imports successfully."""
    import pynhschooldata
    assert pynhschooldata is not None


def test_has_fetch_enr():
    """fetch_enr function is available."""
    import pynhschooldata
    assert hasattr(pynhschooldata, 'fetch_enr')
    assert callable(pynhschooldata.fetch_enr)


def test_has_get_available_years():
    """get_available_years function is available."""
    import pynhschooldata
    assert hasattr(pynhschooldata, 'get_available_years')
    assert callable(pynhschooldata.get_available_years)


def test_has_version():
    """Package has a version string."""
    import pynhschooldata
    assert hasattr(pynhschooldata, '__version__')
    assert isinstance(pynhschooldata.__version__, str)
