
import os
import shutil
import time

# https://stackoverflow.com/questions/39623222/copying-a-file-to-multiple-paths-at-the-same-time

src = '/mnt/Projekt/test.file'
dst = '/mnt/Projekt/SSD/test.file'

copy = shutil.copy2(src, dst)
print(copy)
print("DONE")


