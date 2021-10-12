import os
# import threading
# import shutil
# import time
from contextlib import ExitStack


# Starts the main copy process with one source and multiple destinations
def copy(src, destinations):
    chunks_read = 0
    source_size = calculateSize(src)
    source_chunks = (source_size * len(destinations)) / read_buffer_size

    print("SIZE: %d" % source_size)
    print("CHUNKS: %d" % source_chunks)

    for root, src_subdirs, files in os.walk(src):

        for filename in files:
            source_file = os.path.join(root, filename)
            with open(source_file, "rb") as srcFile:

                # List of all dest. with right path
                destination_filenames = []
                for dst in destinations:
                    destination_filenames.append(os.path.join(dst, os.path.relpath(root, src),
                                                              filename))

                # Open all destination files at once
                with ExitStack() as stack:
                    destination_files = [stack.enter_context(open(filename, "wb"))
                                         for filename in destination_filenames]

                    while True:
                        data = srcFile.read(read_buffer_size)

                        # Ends process for this file if the read data is empty
                        if not data:
                            break

                        for dstFile in destination_files:

                            dstFile.write(data)
                            chunks_read += 1

                        if (chunks_read % 1000 == 0):
                            progress = (chunks_read / source_chunks) * 100
                            print("PROGRESS: %.2f%%" % progress, end='\r')

                    # for dst in destination_filenames:
                        # print("COPIED: " + source_file + " -> " + dst)

    print("PROGRESS: %.2f%%" % 100, end='\r')
    print()
    print("CHUNKS READ: %d" % chunks_read)


# Mirrors the folder structure (if missing) in the dest. directorys
def mirrorFolderStructure(src, destinations):
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


# Calculates the exact size of a directory and its sub directorys
def calculateSize(dir):
    size = 0

    for path, dirs, files in os.walk(dir):
        for f in files:
            fp = os.path.join(path, f)
            size += os.path.getsize(fp)
    return size


if __name__ == '__main__':
    src = '/mnt/Video/Test/Python/Test'
    destinations = ['/mnt/Daten/Test/PYTHON', '/home/benny/Videos/Test/PYTHON', '/mnt/Projekt/Test/Python']
    read_buffer_size = 65_536

    mirrorFolderStructure(src, destinations)
    copy(src, destinations)

    # print(copy)
    print("DONE")
