FROM python:3.13-slim

ENV PYTHONUNBUFFERED="true"

WORKDIR /app

COPY . .

RUN pip install ".[dev]"
