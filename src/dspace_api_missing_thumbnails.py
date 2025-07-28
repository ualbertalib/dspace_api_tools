"""
##############################################################################################
# desc: dspace_api_missing_thumbnails.py:
#     Leverage the https://pypi.org/project/dspace-rest-client
#     to test creating a DSpace API Resoorce Policy creation script.
#     https://github.com/the-library-code/dspace-rest-python/blob/main/dspace_rest_client/client.py
# usage:
#  ./venv/bin/python src/dspace_api_missing_thumbnails.py \
#      --logging_level DEBUG 
#      --output /tmp/missing_thumbnails.txt
# license: CC0 1.0 Universal (CC0 1.0) Public Domain Dedication
# date: July 25, 2025
##############################################################################################
"""
import argparse
import logging
import os
import pathlib

# from dspace_rest_client.client import DSpaceClient
from dspace_rest_client.models import Item

from utils import utilities as utils
from utils.dspace_rest_client_local import DSpaceClientLocal

DSPACE_CLIENT_TOKEN_REFRESH = 500



def parse_args():
    """
    Parse command line arguments
    """
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--output", required=True, help="Location to store output file."
    )
    parser.add_argument(
        "--logging_level", required=False, help="Logging level.", default="INFO"
    )

    return parser.parse_args()

#
def process(dspace_client, output_file, args):
    """
    Main processing function
    """
    items = dspace_client.search_objects_iter(
        query="*:*", dso_type="item", embeds=["thumbnail"]
    )
    count = 0
    for count, item in enumerate(items, start=1):

        if count % DSPACE_CLIENT_TOKEN_REFRESH == 0:
            # not sure if both are needed
            dspace_client.authenticate()
            dspace_client.refresh_token()

        if item.embedded["thumbnail"] is None:
            logging.info("%s (%s)", item.name, item.uuid)
            output_file.write(f"{item.uuid}\n")
    

def main():
    """
    Main entry point
    """

    args = parse_args()

    # Base class should set this as an instance variable in the constructor
    DSpaceClientLocal.ITER_PAGE_SIZE = 100
    dspace_client = DSpaceClientLocal(fake_user_agent=False)
    dspace_client.authenticate()

    # don't set size over 100 otherwise a weird disconnect happens
    # between the requested page size, actual result size and # of pages
    # If 512 items and size is set to 500,
    # https://github.com/DSpace/DSpace/issues/8723
    # http://198.168.187.81:8080/server/api/discover/search/objects?dsoType=collection&page=0&size=500
    # dspace_client.ITER_PAGE_SIZE = 100

    # Configure logging
    log_level = getattr(logging, args.logging_level.upper(), None)
    if not isinstance(log_level, int):
        raise ValueError(f"Invalid log level: {args.log}")
    # Options: DEBUG, INFO, WARNING, ERROR, CRITICAL
    logging.getLogger().setLevel(log_level)

    utils.check_required_env_vars()

    try:
        dspace_client.authenticate()
    except TypeError as e:
        logging.error(
            "Authentication error, check credentials and VPN (if applicable) [%s]", e
        )
        sys.exit(1)

    pathlib.Path(os.path.dirname(args.output)).mkdir(parents=True, exist_ok=True)
    with open(args.output, "wt", encoding="utf-8", newline="") as output_file:
        process(dspace_client, output_file, args)



#
if __name__ == "__main__":
    main()


