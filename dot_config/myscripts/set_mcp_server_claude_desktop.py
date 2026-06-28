import argparse
import json
import os
import sys
from pathlib import Path

CONFIG_FILE = (
    Path.home() / "Library/Application Support/Claude/claude_desktop_config.json"
)
MCP_URL = "http://localhost:8000/mcp"


def load_config() -> dict:
    if CONFIG_FILE.exists():
        return json.loads(CONFIG_FILE.read_text())
    return {"mcpServers": {}}


def save_config(config: dict) -> None:
    CONFIG_FILE.write_text(json.dumps(config, indent=2))
    print(f"✓ Patched {CONFIG_FILE}")
    print("  Restart Claude Desktop to pick up the change.")


def enable(name: str) -> None:
    access_token = os.environ.get("ACCESS_TOKEN")
    if not access_token:
        print("ERROR: AUTHZ_ACCESS_TOKEN is not set", file=sys.stderr)
        sys.exit(1)
    config = load_config()
    config.setdefault("mcpServers", {})
    config["mcpServers"][name] = {
        "command": "npx",
        "args": [
            "mcp-remote",
            MCP_URL,
            "--transport",
            "http-only",
            "--header",
            "Authorization:${AUTH_TOKEN}",
        ],
        "env": {
            "AUTH_TOKEN": f"Bearer {access_token}",
        },
    }
    save_config(config)
    print(f"✓ Enabled MCP server '{name}'")


def disable(name: str) -> None:
    config = load_config()
    servers = config.get("mcpServers", {})
    if name not in servers:
        print(f"ERROR: Server '{name}' not found in config", file=sys.stderr)
        sys.exit(1)
    del servers[name]
    save_config(config)
    print(f"✓ Disabled MCP server '{name}'")


def main() -> None:
    parser = argparse.ArgumentParser(description="Manage Claude Desktop MCP servers")
    subparsers = parser.add_subparsers(dest="command", required=True)

    enable_parser = subparsers.add_parser("enable", help="Register an MCP server")
    enable_parser.add_argument("--name", required=True, help="Server name")

    disable_parser = subparsers.add_parser("disable", help="Remove an MCP server")
    disable_parser.add_argument("--name", required=True, help="Server name to remove")

    args = parser.parse_args()

    if args.command == "enable":
        enable(args.name)
    elif args.command == "disable":
        disable(args.name)


if __name__ == "__main__":
    main()
