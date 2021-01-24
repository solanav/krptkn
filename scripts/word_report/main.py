import psycopg2
import matplotlib.pyplot as plt

from docxtpl import DocxTemplate, InlineImage
from docx.shared import Inches
from datetime import datetime
from collections import Counter
from pprint import pprint

IMAGE_DIR = "images/"
TEMPLATE_DIR = "templates/"
OUTPUT_DIR = "output/"
MAX_FREQ_ITEMS = 10

def get_domain(full_url):
  return '/'.join(full_url.split("/")[:3])

def get_metadata(conn, session):
  cur = conn.cursor()
  cur.execute(f"SELECT * FROM metadata WHERE session='{session}'")
  return cur.fetchall()

def freq_plot(output_name, data, title, xlabel):
  tmp_c = dict(Counter(data))
  x = list(tmp_c.keys())
  y = list(tmp_c.values())
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

  o_subdomains = []
  o_types = []
  o_mk = []
  o_mv = []

  # Convert the frequencies to objects
  for k, freq in Counter(subdomains).items():
    o_subdomains.append({
      "value": k,
      "freq": freq
    })

  for k, freq in Counter(types).items():
    o_types.append({
      "value": k,
      "freq": freq
    })
  
  for k, freq in Counter(mk).items():
    o_mk.append({
      "value": k,
      "freq": freq
    })
  
  for k, freq in Counter(mv).items():
    o_mv.append({
      "value": k,
      "freq": freq
    })

  # Domain freq plot
  freq_plot(
    "subdomains_freq.png",
    subdomains,
    "Frequency",
    "Domains that contained metadata",
  )

  freq_plot(
    "types_freq.png",
    types,
    "Frequency",
    "File type frequency",
  )
  
  freq_plot(
    "mk_freq.png",
    mk,
    "Frequency",
    "Metadata key frequency",
  )

  freq_plot(
    "mv_freq.png",
    mv,
    "Frequency",
    "Metadata value frequency",
  )

  return o_subdomains, o_types, o_mk, o_mv

def generate_report(output_file, data):
  subdomains, types, mk, mv = data

  doc = DocxTemplate(TEMPLATE_DIR + "report_template.docx")
  context = {
    "session_name": "Debugging",
    "current_date": datetime.now().strftime("%I:%M%p on %B %d, %Y"),
    "subdomains": subdomains[:MAX_FREQ_ITEMS],
    "types": types[:MAX_FREQ_ITEMS],
    "mk": mk[:MAX_FREQ_ITEMS],
    "mv": mv[:MAX_FREQ_ITEMS],
    
    # Images
    "domainf_image": InlineImage(doc, 'images/subdomains_freq.png', Inches(6.5)),
    "typef_image": InlineImage(doc, 'images/types_freq.png', Inches(6.5)),
    "mkf_image": InlineImage(doc, 'images/mk_freq.png', Inches(6.5)),
    "mvf_image": InlineImage(doc, 'images/mv_freq.png', Inches(6.5)),
  }

  doc.render(context)
  doc.save(output_file)

def main():
  # Session ID we want to analyze
  session = "debugging_001"

  # Connect to the database
  conn = psycopg2.connect(
    database = "krptkn_dev",
    user     = "krptkn-dev",
    password = "xz3uz3Md4lFeHXOi3lOH",
    host     = "192.168.1.144",
    port     = "5432"
  )

  # Get metadata from database and analyze it
  raw_metadata = get_metadata(conn, session)
  metadata_analysis = metadata_analyze(raw_metadata)

  # Save the report
  generate_report(OUTPUT_DIR + "report.docx", metadata_analysis)

if __name__ == "__main__":
  main()