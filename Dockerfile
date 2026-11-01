# Task 4 - sentiment-worker:latest built from alpine
FROM alpine:latest

# busybox-extras gives a tiny web server so the container keeps running on port 80
RUN apk add --no-cache busybox-extras \
    && mkdir -p /www \
    && echo "Sentiment Engine Ingesting" > /www/index.html

EXPOSE 80

# Prints the required message, then serves it on port 80 (keeps container "Up" in docker ps)
CMD ["sh", "-c", "echo 'Sentiment Engine Ingesting' && exec busybox-extras httpd -f -p 80 -h /www"]
