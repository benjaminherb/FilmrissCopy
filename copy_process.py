import os
import shutil
import time
from contextlib import ExitStack

# https://stackoverflow.com/questions/39623222/copying-a-file-to-multiple-paths-at-the-same-time
# https://stackoverflow.com/questions/9104040/python-what-is-the-fastest-way-i-can-copy-files-from-a-source-folder-to-multip
# https://stackoverflow.com/questions/2212643/python-recursive-folder-read/2212698#2212698

def copy (src, destinations):
    for root, src_subdirs, files in os.walk(src):

        for filename in files:
            source_file = os.path.join(root, filename)
            with open(source_file, "rb") as srcFile:

                destination_filenames=[]
                for dst in destinations:
                    destination_filenames.append(os.path.join(dst, os.path.relpath(root,src), filename)) # List of all destinations with the right path

                with ExitStack() as stack: # Open all destination files at once
                    destination_files = [stack.enter_context(open(filename, "wb")) for filename in destination_filenames]

                    while True:
                        data = srcFile.read(read_buffer_size)

                        if not data:
                            break

                        for dstFile in destination_files:
                            dstFile.write(data)




def mirrorFolderStructure (src, destinations):
    for dir in destinations:
        if not os.path.isdir(dir):
            os.makedirs(dir)
            print("CREATED: " + dir)
        else:
           print("Folder does already exits!")

    for root, subdirs, files in os.walk(src):

        for dir in subdirs:
            for dst in destinations:
                newDir = os.path.join(dst, os.path.relpath(root, src), dir)
                if not os.path.isdir(newDir):
                    os.mkdir(newDir)
                    print("CREATED: " + newDir)
                else:
                    print(newDir + " does already exits!")




src = '/mnt/Projekt/TEST'
destinations = ['/mnt/Daten/Test/PYTHON','/home/benny/Videos/Test/PYTHON']
read_buffer_size = 65_536

mirrorFolderStructure(src, destinations)
copy(src, destinations)

# print(copy)
print("DONE")
