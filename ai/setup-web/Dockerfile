FROM python:3.12-slim

WORKDIR /app

RUN pip install --no-cache-dir flask

COPY app.py ./
COPY templates/ templates/
COPY static/ static/

ENV FLASK_ENV=production
EXPOSE 5555

CMD ["python3", "app.py"]
