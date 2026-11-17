FROM alpine:3.23
RUN apk add --no-cache openssl
COPY init.sh /init.sh
RUN sed -i 's/\r$//' /init.sh
ENTRYPOINT ["/bin/sh", "/init.sh"]
