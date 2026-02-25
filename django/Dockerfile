FROM python:3.13.2-bookworm

ENV PYTHONUNBUFFERED=1

RUN apt-get update && \
    apt-get install -y vim-tiny && \
    rm -rf /var/lib/apt/lists/*


COPY . /app
WORKDIR /app

RUN pip install --no-cache-dir -r requirements.txt

RUN mkdir -p /app/db
VOLUME /app/db

CMD ["./start.sh"]
