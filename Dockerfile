# Extend from the official Elixir image
FROM elixir:latest

# Create krptkn directory and copy the project
RUN mkdir /krptkn
COPY . /krptkn
WORKDIR /krptkn

# Environment variables
ENV PGUSER postgres
ENV PGPASSWORD postgres
ENV PGDATABASE database_name
ENV PGHOST db
ENV PGPORT 5432

# Install hex package manager
# By using --force, we don’t need to type “Y” to confirm the installation
RUN mix local.hex --force

# Install dependencies
RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash -
RUN wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
RUN dpkg -i erlang-solutions_2.0_all.deb
RUN rm erlang-solutions_2.0_all.deb
RUN apt-get update
RUN apt-get install -y cmake \
    erlang erlang-dev erlang-parsetools erlang-tools \
    postgresql-client \
    inotify-tools nodejs

# Compile assets
RUN npm cache clean --force
RUN npm install

# Install rebar3
RUN mix local.rebar --force

# Get mix dependencies
RUN mix deps.get
RUN mix deps.compile

# Compile the project
RUN mix compile

# Run everything
RUN chmod +x /krptkn/entrypoint.sh
CMD ["/krptkn/entrypoint.sh"]