import psycopg2

class Database():
    def __init__(self):
        # Connect to the database
        conn = psycopg2.connect(
            database = "krptkn_dev",
            user     = "krptkn-dev",
            password = "xz3uz3Md4lFeHXOi3lOH",
            host     = "192.168.1.144",
            port     = "5432"
        )

        self.conn = conn

    def get_last_entry(self, session):
        cur = self.conn.cursor()
        cur.execute(f"SELECT * FROM public.urls WHERE session='{session}' ORDER BY inserted_at DESC LIMIT 1")
        return cur.fetchone()

    def get_first_entry(self, session):
        cur = self.conn.cursor()
        cur.execute(f"SELECT * FROM public.urls WHERE session='{session}' ORDER BY inserted_at ASC LIMIT 1")
        return cur.fetchone()

    def get_metadata(self, session):
        cur = self.conn.cursor()
        cur.execute(f"SELECT * FROM metadata WHERE session='{session}'")
        return cur.fetchall()