"""Record identical gestures against the original and Flutter comparison fixtures.

python tool/compare_glass_adb.py reference
python tool/compare_glass_adb.py flutter
Requires the 1080x2400, 420dpi emulator and the corresponding comparison APK.
"""
import pathlib
import subprocess
import sys
import time

ADB = pathlib.Path.home() / 'AppData/Local/Android/Sdk/platform-tools/adb.exe'
MODE = sys.argv[1]
if MODE not in ('reference', 'flutter'):
    raise SystemExit('Choose reference or flutter')
PACKAGE = 'com.kyant.backdrop.catalog' if MODE == 'reference' else 'com.example.bottom_nav_demo'
OUT = pathlib.Path(__file__).resolve().parents[1] / 'build/visual-checks'
OUT.mkdir(parents=True, exist_ok=True)


def adb(*args):
    return subprocess.run([str(ADB), '-s', 'emulator-5554', *args], check=True,
                          capture_output=True, text=True, encoding='utf-8').stdout.strip()


def capture(name):
    remote = f'/sdcard/{MODE}-{name}.png'
    adb('shell', 'screencap', '-p', remote)
    adb('pull', remote, str(OUT / f'{MODE}-{name}.png'))


if '1080x2400' not in adb('shell', 'wm', 'size'):
    raise SystemExit('Fixture expects a 1080x2400 emulator')
adb('shell', 'am', 'force-stop', PACKAGE)
args = ['shell', 'am', 'start', '-n', f'{PACKAGE}/.MainActivity']
if MODE == 'reference':
    args += ['--ez', 'compare', 'true']
adb(*args)
expected = 'Tab 1' if MODE == 'reference' else '首页'
for attempt in range(15):
    result = subprocess.run([str(ADB), '-s', 'emulator-5554', 'shell',
        'uiautomator', 'dump', '/sdcard/glass-ready.xml'], capture_output=True)
    if result.returncode == 0 and expected in adb('shell', 'cat', '/sdcard/glass-ready.xml'):
        break
    time.sleep(1)
else:
    raise SystemExit('App did not reach the comparison fixture; no gestures sent')
time.sleep(1)
remote_video = f'/sdcard/{MODE}-motion.mp4'
video = subprocess.Popen([str(ADB), '-s', 'emulator-5554', 'shell', 'screenrecord',
                          '--size', '540x1200', '--bit-rate', '4000000',
                          '--time-limit', '9', remote_video], stdout=subprocess.DEVNULL)
try:
    capture('idle')
    adb('shell', 'input', 'touchscreen', 'motionevent', 'DOWN', '135', '2200')
    time.sleep(.3)
    capture('pressed')
    adb('shell', 'input', 'touchscreen', 'motionevent', 'MOVE', '540', '2200')
    time.sleep(.3)
    capture('dragged')
finally:
    adb('shell', 'input', 'touchscreen', 'motionevent', 'UP', '540', '2200')
time.sleep(.7)
capture('released')
adb('shell', 'input', 'swipe', '540', '2200', '920', '2200', '550')
time.sleep(.7)
adb('shell', 'input', 'tap', '335', '2200')
video.wait(timeout=15)
adb('pull', remote_video, str(OUT / f'{MODE}-motion.mp4'))
print(f'{MODE}: saved four frames and gesture recording to {OUT}')
