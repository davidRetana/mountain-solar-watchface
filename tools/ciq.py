"""Build, simulate or test installed Connect IQ profiles from the project root."""

import argparse
import os
from pathlib import Path
import re
import subprocess
import sys
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]


def sdk_path(explicit):
    if explicit:
        return Path(explicit).expanduser().resolve()
    if os.environ.get("CIQ_SDK"):
        return Path(os.environ["CIQ_SDK"]).expanduser().resolve()
    config = Path.home() / "Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg"
    if config.is_file():
        return Path(config.read_text().strip())
    raise ValueError("Indica el SDK con --sdk /ruta/al/sdk o la variable CIQ_SDK.")


def environment():
    env = os.environ.copy()
    # The project's macOS setup uses Homebrew OpenJDK. Respect an explicit JDK.
    java = Path("/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home")
    if not env.get("JAVA_HOME") and java.is_dir():
        env["JAVA_HOME"] = str(java)
        env["PATH"] = str(java / "bin") + os.pathsep + env.get("PATH", "")
    return env


def invoke(command, env, tests=False):
    if not tests:
        subprocess.run(command, cwd=ROOT, env=env, check=True)
        return
    # Some macOS monkeydo versions return 1 even when all tests pass. Require
    # the final explicit result, never treat an arbitrary nonzero exit as OK.
    result = subprocess.run(command, cwd=ROOT, env=env, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(result.stdout, end="", flush=True)
    summaries = re.findall(r"^(PASSED|FAILED) \(passed=(\d+), failed=(\d+), errors=(\d+)\)\s*$",
                           result.stdout, re.MULTILINE)
    if summaries:
        status, passed, failed, errors = summaries[-1]
        if (status == "PASSED" and int(passed) > 0 and failed == "0"
                and errors == "0" and result.returncode in (0, 1)):
            return
    raise subprocess.CalledProcessError(result.returncode or 1, command)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("build", "run", "test"))
    parser.add_argument("devices", nargs="+", help="Perfiles, por ejemplo fenix7s fenix7x")
    parser.add_argument("--sdk", help="Directorio del SDK; por defecto el SDK activo en macOS")
    parser.add_argument("--key", default=str(ROOT / "developer_key"), help="Clave local de desarrollador")
    args = parser.parse_args()
    try:
        sdk = sdk_path(args.sdk)
        key = Path(args.key).expanduser().resolve()
        if not key.is_file():
            raise ValueError("Falta la clave de desarrollador. Indícala con --key /ruta/a/clave-local.")
        products = {node.attrib["id"] for node in ET.parse(ROOT / "manifest.xml").iter()
                    if node.tag.endswith("}product")}
        for device in args.devices:
            if device not in products:
                raise ValueError(f"El perfil {device} no está declarado en manifest.xml.")
        for tool in ("monkeyc", "monkeydo"):
            if not (sdk / "bin" / tool).is_file():
                raise ValueError(f"No se encuentra {tool} en el SDK seleccionado.")
        env = environment()
        (ROOT / "bin").mkdir(exist_ok=True)
        for device in args.devices:
            testing = args.action == "test"
            output = ROOT / "bin" / f"{'tests' if testing else 'mountain'}-{device}.prg"
            print(f"\n{args.action}: {device}", flush=True)
            command = [str(sdk / "bin/monkeyc"), "-f",
                       "tests/solar.jungle" if testing else "monkey.jungle",
                       "-d", device, "-o", str(output), "-y", str(key), "-w", "-l", "1"]
            if testing:
                command.append("-t")
            invoke(command, env)
            if args.action != "build":
                command = [str(sdk / "bin/monkeydo"), str(output), device]
                if testing:
                    command.append("-t")
                invoke(command, env, tests=testing)
        return 0
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f"Error: {error}", file=sys.stderr)
        if args.action != "build":
            print("Para ejecutar, abre primero el simulador Connect IQ del SDK seleccionado.",
                  file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
