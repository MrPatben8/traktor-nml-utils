import logging
from collections.abc import Iterator
from pathlib import Path

import typer

from traktor_nml_utils import TraktorCollection, TraktorHistory, is_history_file

logger = logging.getLogger(__name__)

app = typer.Typer()


@app.callback()
def main(
    verbose: int = typer.Option(
        0, "--verbose", "-v", count=True, help="Verbose logging"
    ),
    debug: bool = typer.Option(False, "--debug", "-d", help="Debug logging"),
):
    loglevel = logging.WARNING
    if verbose:
        loglevel = logging.INFO
    elif debug:
        loglevel = logging.DEBUG
    logging.basicConfig(level=loglevel)


@app.command()
def traktor_import(nml: Path):
    """NML import from file or directory."""
    nml_files: Iterator[Path]
    if nml.is_dir():
        nml_files = nml.glob("**/*.nml")
    else:
        nml_files = iter([nml])

    for nml_file in nml_files:
        print(f"Importing NML: {nml_file}")
        if is_history_file(nml_file):
            TraktorHistory(nml_file)
        else:
            TraktorCollection(nml_file)


if __name__ == "__main__":
    app()
