FROM python:3.12-alpine

ENV PORT=5000 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY --chown=10001:10001 app/app.py ./app.py

# The application only listens on 5000, an unprivileged port.
EXPOSE 5000
USER 10001:10001

CMD ["python", "/app/app.py"]