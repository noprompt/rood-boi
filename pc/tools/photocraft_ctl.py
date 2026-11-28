#!/usr/bin/env python3
"""A client of PhotoCraft's localhost control server (JSON lines over TCP; /usr/share/doc/photocraft/control-protocol.md): the challenge
handshake (the token never goes over the wire, and the server proves it holds it first), then `call(method, **params)` and
`execute(command, **params)` (engine.execute: any of PhotoCraft's commands). Standard library only."""
import hashlib
import hmac
import json
import os
import pathlib
import secrets
import socket


class CtlError(Exception):
    """The server refused a request (its message), or could not be reached or trusted."""


class Control:
    def __init__(self, port, token, host="127.0.0.1", timeout=65.0):
        """`token`: the 64 hex digits (or a path to the token file)."""
        self.port, self.token_path = port, None
        if isinstance(token, (str, os.PathLike)) and pathlib.Path(str(token)).is_file():
            self.token_path = pathlib.Path(token)
            token = self.token_path.read_text()
        self.token = str(token).strip()
        try:
            self.sock = socket.create_connection((host, port), timeout=5)
        except OSError as e:
            raise CtlError(f"PhotoCraft's control port {port} is not reachable ({e})") from e
        self.sock.settimeout(timeout)
        self.file = self.sock.makefile("rwb")
        self.serial = 0
        self.authenticate()

    def proof(self, label, client_nonce, server_nonce):
        return hmac.new(self.token.encode(), f"photocraft-control-v1 {label}\n{client_nonce}\n{server_nonce}".encode(), hashlib.sha256).hexdigest()

    def authenticate(self):
        nonce = secrets.token_hex(32)
        got = self.call("auth.challenge", clientNonce=nonce)
        if not hmac.compare_digest(got["serverProof"], self.proof("server", nonce, got["serverNonce"])):
            self.close()
            raise CtlError("the listener on the control port does not hold the token (not the PhotoCraft that was started)")
        self.call("auth", proof=self.proof("client", nonce, got["serverNonce"]))

    def call(self, method, **params):
        self.serial += 1
        try:
            self.file.write((json.dumps({"id": self.serial, "method": method, "params": params}) + "\n").encode())
            self.file.flush()
            line = self.file.readline()
        except (OSError, ValueError) as e:
            raise CtlError(f"the control connection failed ({e})") from e
        if not line:
            raise CtlError("the control connection closed")
        reply = json.loads(line)
        if not reply.get("ok"):
            raise CtlError(str(reply.get("error")))
        return reply.get("result")

    def execute(self, command, **params):
        return self.call("engine.execute", command=command, params=params)

    def close(self):
        try:
            self.file.close()
            self.sock.close()
        except OSError:
            pass
