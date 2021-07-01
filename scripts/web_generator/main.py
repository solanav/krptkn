import os
import random
import string
import shutil
from tqdm import tqdm

def random_string():
    s = random.choices(string.ascii_uppercase + string.digits, k=10)
    return ''.join(s)

def random_link():
    name = random_string()
    return name, f"<a href=\"{name}.html\">{random_string()}</a>"

def main():
    links = [random_link() for i in range(0, 100)]

    shutil.rmtree("www")
    os.mkdir("www")
    f = open("www/index.html", "w")

    for l, ll in tqdm(links):
        # Write link to index
        f.write(f"{ll}\n")

        # Create the file the link refers to
        f2 = open(f"www/{l}.html", "w")
        links2 = links
        random.shuffle(links2)
        for l2, ll2 in links2:
            # Write link to file
            f2.write(f"{ll2}\n")



if __name__ == "__main__":
    main()