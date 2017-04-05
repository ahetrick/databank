#!/usr/bin/env python
#
# GNU General Public License https://www.gnu.org/licenses/gpl-3.0.txt
#
"""

Illinois Data Bank Datafile.
Usage:
    illinois_data_bank_datafile.py [-h] <DATASET> <TOKEN> <FILE> [<SYSTEM>]

Upload FILE to an existing draft DATASET created in Illinois Data Bank (https://databank.illinois.edu),
authenticating with TOKEN on SYSTEM, which is the production system by default.

Arguments:
  FILE      input file
  DATASET   dataset key, obtained on screen opened by API button on dataset edit screen
  TOKEN     API token, obtained on screen opened by API button on dataset edit screen
  SYSTEM    optional system indicator (local | development | production), default is production

Options:
  -h --help

"""
from __future__ import division
from __future__ import print_function
from docopt import docopt


import sys
import os
import errno

import requests


if __name__ == '__main__':
    arguments = docopt(__doc__)
    # print(arguments)

chunksize = 2097152
success_code = 200

token = arguments["<TOKEN>"]
dataset_key = arguments["<DATASET>"]
filepath = arguments["<FILE>"]
system = "production"
endpoint = "http"

def upload_file():
    # if the FILE argument is a filepath of a file that can be found, try to upload it
    if os.path.isfile(filepath):
        # store just the name part of the filepath to pass in post
        filepath_split = filepath.split('/')
        filename = filepath_split[-1]
        print ("uploading " + filename + " ...")

        # initiate upload
        # note: verify=False is only needed for the self-signed certificate on rds-dev

        with open(filepath, 'rb') as f:
            filesize = os.fstat(f.fileno()).st_size

            setup_response = requests.post(endpoint,
                                           headers={'Authorization': 'Token token=' + token},
                                           data={'filename': filename, 'phase': 'setup', 'filesize':filesize},
                                           verify=(system != "development"))

            if str(setup_response.status_code) == str(success_code):
                # transfer file in chunks

                numchunks = (filesize//chunksize)
                if(filesize % chunksize != 0):
                    numchunks+=1
                current_chunk = 1

                print("transferring file in chunks ... ")
                chunk = f.read(chunksize)
                previous_size = 0
                while chunk:

                    chunk_transfer_response = requests.post(endpoint,
                                                            headers={'Authorization': 'Token token=' + token},
                                                            files={"bytechunk": chunk},
                                                            data={'filename': filename, 'phase': 'transfer',
                                                                  'previous_size': previous_size},
                                                            verify=(system != "development"))

                    if str(chunk_transfer_response.status_code) == str(success_code):
                        previous_size = previous_size + chunksize
                        chunk = f.read(chunksize)

                        print("successfully transferred chunk " + str(current_chunk) + " of " + str(numchunks))
                        current_chunk += 1
                    else:
                        print("transfer response status:" + str(chunk_transfer_response.status_code))
                        print(chunk_transfer_response.text)
                        break

                # after file is transferred, send verify signal, which is required to actually add the file to the dataset
                verification_response = requests.post(endpoint,
                                                      headers={'Authorization': 'Token token=' + token},
                                                      data={'filename': filename, 'phase': 'verify', 'checksum': 'not implemented'},
                                                      verify=(system != "development"))
                print("transfer verification status code: " + str(verification_response.status_code))
                print(verification_response.text)
            else:
                print("setup response status: " + str(setup_response.status_code))
                print(setup_response.text)

    else:
        raise RuntimeError("Unable to find file: %s" % filepath)


# If a SYSTEM argument is provided, validate it, otherwise use production as default.
if (arguments["<SYSTEM>"]) != None:
    valid_system_list=["local", "development", "production"]
    if any(arguments["<SYSTEM>"] in s for s in valid_system_list):
        system = arguments["<SYSTEM>"]
    else:
        print(arguments)
        print("SYSTEM argument must be one of local|development|production, production is default.\n")
        sys.exit("python " + sys.argv[0] + " -h for help.")

# generate endpoint from system and dataset

if (system == 'production'):
    endpoint+="s://databank.illinois.edu/api/dataset/"+dataset_key+"/datafile"
elif (system == 'development'):
    endpoint += "s://rds-dev.library.illinois.edu/api/dataset/" + dataset_key + "/datafile"
elif (system == 'local'):
    endpoint += "://localhost:3000/api/dataset/" + dataset_key + "/datafile"
else:
    # should not be any logical way to get here
    sys.exit('Internal Error, please contact the Research Data Service databank@library.illinois.edu')

try:
    upload_file()
except Exception as ex:
    print("Exception: %s" % ex)


