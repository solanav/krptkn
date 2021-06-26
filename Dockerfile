# Extend from the official Elixir image
FROM debian:10

# Create krptkn directory and copy the project
RUN mkdir /krptkn
COPY . /krptkn
WORKDIR /krptkn

# Environment variables
ENV LANG C.UTF-8
ENV PGUSER postgres
ENV PGPASSWORD postgres
ENV PGDATABASE krptkn
ENV PGHOST db
ENV PGPORT 5432

# Install dependencies
RUN apt-get update
RUN apt-get install -y wget curl git gnupg cmake postgresql-client inotify-tools libextractor-dev

# Install erlang and elixir
RUN wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
RUN dpkg -i erlang-solutions_2.0_all.deb
RUN rm erlang-solutions_2.0_all.deb
RUN apt-get update
RUN apt-get install -y esl-erlang elixir

# Compile assets
# RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs npm
RUN npm cache clean --force
RUN npm install

# Install hex package manager (elixir)
RUN mix local.hex --force

# Install rebar3 package manager (erlang)
RUN mix local.rebar --force

# Get mix dependencies and compile them
RUN mix deps.get
RUN mix deps.compile

# Compile the project
RUN mix compile

# Run everything
RUN chmod +x /krptkn/entrypoint.sh
CMD ["/krptkn/entrypoint.sh"]