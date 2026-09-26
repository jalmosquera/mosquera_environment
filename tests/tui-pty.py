#!/usr/bin/env python3
"""Exercise interactive TUI input through a controlling pseudo-terminal."""
import fcntl
import os
import pty
import select
import termios
import time


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def start():
    master, slave = pty.openpty()
    pid = os.fork()
    if pid == 0:
        try:
            os.setsid()
            fcntl.ioctl(slave, termios.TIOCSCTTY, 0)
            os.dup2(slave, 0)
            os.dup2(slave, 1)
            os.dup2(slave, 2)
            os.close(master)
            if slave > 2:
                os.close(slave)
            os.chdir(ROOT)
            os.execvp('bash', ['bash', '-ceu', 'test -t 0; test -t 1; test -t 2; test -r /dev/tty; exec ./install'])
        finally:
            os._exit(127)
    os.close(slave)
    return master, pid


def read_until(master, text, timeout=10):
    output = b''
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        ready, _, _ = select.select([master], [], [], 0.1)
        if master not in ready:
            continue
        try:
            chunk = os.read(master, 4096)
        except OSError:
            break
        output += chunk
        if text in output:
            return
    raise RuntimeError('timeout waiting for {!r}: {!r}'.format(text, output[-400:]))


def stop(master, pid):
    os.kill(pid, 15)
    os.close(master)


def simulation(enter):
    master, pid = start()
    try:
        read_until(master, b'Enter para seleccionar')
        os.write(master, b'd')
        read_until(master, b'Iniciar simulaci')
        os.write(master, enter)
        read_until(master, b'DRY RUN: no changes will be made.', 30)
    finally:
        stop(master, pid)


def navigation_and_escape():
    master, pid = start()
    try:
        read_until(master, b'Enter para seleccionar')
        os.write(master, b'\x1b[B')
        read_until(master, b'>  d   Simulaci')
        os.write(master, b'\r')
        read_until(master, b'Iniciar simulaci')
        os.write(master, b'\x1b')
    finally:
        stop(master, pid)


def profile_shortcut_and_escape():
    master, pid = start()
    try:
        read_until(master, b'Enter para seleccionar')
        os.write(master, b'p')
        read_until(master, b'Seleccionar perfil')
        os.write(master, b'\x1b')
    finally:
        stop(master, pid)


def shortcuts():
    for key, expected in ((b'i', b'Iniciar instalaci'), (b'c', b'Comprobaci'), (b'h', b'Ayuda')):
        master, pid = start()
        try:
            read_until(master, b'Enter para seleccionar')
            os.write(master, key)
            read_until(master, expected)
        finally:
            stop(master, pid)


def interrupt():
    master, pid = start()
    try:
        read_until(master, b'Enter para seleccionar')
        os.kill(pid, 2)
    finally:
        stop(master, pid)


simulation(b'\r')
simulation(b'\n')
navigation_and_escape()
profile_shortcut_and_escape()
shortcuts()
interrupt()
print('PASS')
