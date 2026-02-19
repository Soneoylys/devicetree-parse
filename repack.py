#!/usr/bin/env python3
import json
import sys
from typing import Any


def process_bytes(value: str) -> bytes:
    out = bytearray()
    i = 0
    while i < len(value):
        if i + 3 < len(value) and value[i] == "\\" and value[i + 1] == "x":
            out.append(int(value[i + 2 : i + 4], 16))
            i += 4
        else:
            out.extend(value[i].encode("latin1"))
            i += 1
    return bytes(out)


def encode_property(prop: dict[str, Any]) -> bytes:
    name = prop["name"].encode("utf-8")
    if len(name) >= 32:
        raise ValueError(f"property name too long: {prop['name']}")
    prop_len = int(prop["length"])
    flags = int(prop["flags"])

    header = bytearray(36)
    header[: len(name)] = name
    header[32:34] = prop_len.to_bytes(2, "little", signed=False)
    header[34:36] = flags.to_bytes(2, "little", signed=False)

    value = prop.get("value", "")
    if isinstance(value, int):
        if prop_len not in (1, 2, 4, 8):
            raise ValueError(f"unsupported integer size: {prop_len}")
        raw = int(value).to_bytes(prop_len, "little", signed=False)
    elif isinstance(value, str):
        raw = process_bytes(value)
    else:
        raw = b""

    if len(raw) < prop_len:
        raw = raw + b"\x00" * (prop_len - len(raw))
    else:
        raw = raw[:prop_len]

    padded = (prop_len + 3) & ~3
    if padded > prop_len:
        raw = raw + b"\x00" * (padded - prop_len)

    return bytes(header) + raw


def encode_node(node: list[Any]) -> bytes:
    props: list[bytes] = []
    children: list[bytes] = []
    for item in node:
        if isinstance(item, dict):
            props.append(encode_property(item))
        elif isinstance(item, list):
            children.append(encode_node(item))
        else:
            raise ValueError("node entries must be objects (properties) or arrays (children)")

    out = bytearray()
    out += len(props).to_bytes(4, "little", signed=False)
    out += len(children).to_bytes(4, "little", signed=False)
    for prop in props:
        out += prop
    for child in children:
        out += child
    return bytes(out)


def main() -> int:
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <devicetree.json> <output>")
        return 1

    with open(sys.argv[1], "r", encoding="utf-8") as fh:
        doc = json.load(fh)

    if "device-tree" not in doc or not isinstance(doc["device-tree"], list):
        raise ValueError('input JSON must contain a top-level "device-tree" array')

    encoded = encode_node(doc["device-tree"])
    with open(sys.argv[2], "wb") as fh:
        fh.write(encoded)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
