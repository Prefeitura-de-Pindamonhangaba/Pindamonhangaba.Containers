set -eu
umask 077

cert=/certs/default-listener.crt
key=/certs/default-listener.key
encryption_key=/keys/default-aesgcm256-v1.bin

if [ ! -e "$cert" ] && [ ! -e "$key" ]; then
    openssl req -x509 -newkey rsa:2048 -sha256 -days 365 -nodes \
        -keyout "$key.tmp" -out "$cert.tmp" -subj /CN=localhost \
        -addext "subjectAltName=$WSO2_TLS_SAN"
    mv "$key.tmp" "$key"
    mv "$cert.tmp" "$cert"
fi

if [ ! -s "$cert" ] || [ ! -s "$key" ]; then
    echo 'O volume TLS deve conter o certificado e a chave privada.' >&2
    exit 1
fi

if [ ! -e "$encryption_key" ]; then
    openssl rand -out "$encryption_key.tmp" 32
    mv "$encryption_key.tmp" "$encryption_key"
fi

test "$(wc -c < "$encryption_key")" -eq 32
chown 10001 "$cert" "$key" "$encryption_key"
chmod 644 "$cert"
chmod 600 "$key" "$encryption_key"
