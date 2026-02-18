FROM python:3.13.2-bookworm

ENV PYTHONUNBUFFERED=1

COPY . /app
WORKDIR /app

RUN pip install --no-cache-dir -r requirements.txt

CMD ["./start.sh"]
