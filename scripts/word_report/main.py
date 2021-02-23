import matplotlib.pyplot as plt
import argparse

from database import Database
from docxtpl import DocxTemplate, InlineImage
from docx.shared import Inches
from datetime import datetime
from collections import Counter

IMAGE_DIR = "images/"
TEMPLATE_DIR = "templates/"
OUTPUT_DIR = "output/"

MAX_FREQ_ITEMS = 15
MAX_NAME_LEN = 50

def get_domain(full_url):
  return full_url.split("/")[2]

def freq_plot(output_name, data, title, xlabel):
  tmp_c = dict(Counter(data))
  tmp_c = sorted(tmp_c.items(), key=lambda item: item[1])[-MAX_FREQ_ITEMS:]

  x = []
  y = []
  for xx, yy in tmp_c:
    x.append(xx[:MAX_NAME_LEN])
    y.append(yy)

  plt.figure(figsize = (10, 5))
  plt.barh(x, y, align='center', height=.8)
  plt.xlabel(title)
  plt.title(xlabel)
  plt.tight_layout()
  plt.savefig(IMAGE_DIR + output_name)
  plt.clf()


def metadata_analyze(raw_metadata):
  session = raw_metadata[0][1]

  subdomains = []
  types = []
  mk = []
  mv = []

  # Split the elements to lists
  for r in raw_metadata:
    subdomains.append(get_domain(r[2]))
    types.append(r[3])

    for k, v in r[4].items():
      mk.append(k)
      mv.append(v)

  # Convert the frequencies to objects
  o_subdomains = [{"value": k, "freq": freq} for k, freq in Counter(subdomains).items()]
  o_types = [{"value": k, "freq": freq} for k, freq in Counter(types).items()]
  o_mk = [{"value": k, "freq": freq} for k, freq in Counter(mk).items()]
  o_mv = [{"value": k, "freq": freq} for k, freq in Counter(mv).items()]

  o_subdomains = sorted(o_subdomains, reverse=True, key=lambda x: x["freq"])[:10]
  o_types = sorted(o_types, reverse=True, key=lambda x: x["freq"])[:10]
  o_mk = sorted(o_mk, reverse=True, key=lambda x: x["freq"])[:10]
  o_mv = sorted(o_mv, reverse=True, key=lambda x: x["freq"])[:10]

  # Domain freq plot
  freq_plot("subdomains_freq.png", subdomains, "Frequency", "Domains that contained metadata")
  freq_plot("types_freq.png", types, "Frequency", "File type frequency")
  freq_plot("mk_freq.png", mk, "Frequency", "Metadata key frequency")
  freq_plot("mv_freq.png", mv, "Frequency", "Metadata value frequency")

  return o_subdomains, o_types, o_mk, o_mv

def generate_report(db, session, output_file, data):
  subdomains, types, mk, mv = data

  first_entry = list(db.get_first_entry(session))

  doc = DocxTemplate(TEMPLATE_DIR + "report_template.docx")
  context = {
    "session_name": session,
    "current_date": datetime.now().strftime("%I:%M%p on %B %d, %Y"),
    "subdomains": subdomains[:MAX_FREQ_ITEMS],
    "types": types[:MAX_FREQ_ITEMS],
    "mk": mk[:MAX_FREQ_ITEMS],
    "mv": mv[:MAX_FREQ_ITEMS],

    # Header info
    "base_domain": get_domain(first_entry[2]),
    "starting_url": first_entry[2],
    "danger_level": "??%",
    "first_entry": str(first_entry[4]),
    "last_entry": str(db.get_last_entry(session)[4]),

    # Images
    "domainf_image": InlineImage(doc, 'images/subdomains_freq.png', Inches(6.5)),
    "typef_image": InlineImage(doc, 'images/types_freq.png', Inches(6.5)),
    "mkf_image": InlineImage(doc, 'images/mk_freq.png', Inches(6.5)),
    "mvf_image": InlineImage(doc, 'images/mv_freq.png', Inches(6.5)),
  }

  doc.render(context)
  doc.save(output_file)

def main():
  # Parse arguments
  parser = argparse.ArgumentParser(description='Generate metadata report for the given session.')
  parser.add_argument('session', type=str, help='name of the session')
  args = parser.parse_args()
  session = args.session

  # Get metadata from database and analyze it
  db = Database()
  raw_metadata = db.get_metadata(session)
  metadata_analysis = metadata_analyze(raw_metadata)

  # Save the report
  generate_report(db, session, OUTPUT_DIR + "report.docx", metadata_analysis)

if __name__ == "__main__":
  main()