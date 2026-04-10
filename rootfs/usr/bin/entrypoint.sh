#!/usr/bin/with-contenv bashio
set -e

# Configuration variables
CONFIG_FILE="/etc/ntfy/server.yml"

# Create config directory if it doesn't exist
mkdir -p /etc/ntfy
mkdir -p /var/cache/ntfy
mkdir -p /var/lib/ntfy

# Generate server.yml configuration
bashio::log.info "Generating ntfy configuration..."

{
    # Listen port
    echo "listen-http: \":$(bashio::config 'listen_port')\""
    
    # Base URL (if set)
    if bashio::config.has_value 'base_url'; then
        BASE_URL=$(bashio::config 'base_url')
        if [ -n "$BASE_URL" ]; then
            echo "base-url: \"$BASE_URL\""
        fi
    fi
    
    # Cache duration
    CACHE_DURATION=$(bashio::config 'cache_duration')
    echo "cache-duration: \"$CACHE_DURATION\""
    echo "cache-file: \"/var/cache/ntfy/cache.db\""
    
    # Timezone
    TZ=$(bashio::config 'timezone')
    echo "timezone: \"$TZ\""
    
    # Attachment settings
    if bashio::config.true 'attachment_enabled'; then
        echo "attachment-cache-dir: \"/var/cache/ntfy/attachments\""
        echo "attachment-total-size-limit: \"5G\""
        echo "attachment-file-size-limit: \"15M\""
        echo "attachment-expiry-duration: \"3h\""
    fi
    
    # Authentication settings
    if bashio::config.true 'auth_enabled'; then
        echo "auth-file: \"/var/lib/ntfy/user.db\""
        
        if bashio::config.has_value 'auth_default_access'; then
            AUTH_DEFAULT_ACCESS=$(bashio::config 'auth_default_access')
            echo "auth-default-access: \"$AUTH_DEFAULT_ACCESS\""
        else
            echo "auth-default-access: \"read-write\""
        fi
    fi
    
    # Firebase (if configured)
    if bashio::config.has_value 'firebase_key_file'; then
        FIREBASE_KEY_FILE=$(bashio::config 'firebase_key_file')
        if [ -n "$FIREBASE_KEY_FILE" ] && [ -f "$FIREBASE_KEY_FILE" ]; then
            echo "firebase-key-file: \"$FIREBASE_KEY_FILE\""
        fi
    fi
    
    # SMTP settings (if configured)
    if bashio::config.has_value 'smtp_sender_addr'; then
        SMTP_ADDR=$(bashio::config 'smtp_sender_addr')
        SMTP_FROM=$(bashio::config 'smtp_sender_from')
        if [ -n "$SMTP_ADDR" ]; then
            echo "smtp-sender-addr: \"$SMTP_ADDR\""
            if [ -n "$SMTP_FROM" ]; then
                echo "smtp-sender-from: \"$SMTP_FROM\""
            fi
            if bashio::config.has_value 'smtp_sender_user'; then
                SMTP_USER=$(bashio::config 'smtp_sender_user')
                SMTP_PASS=$(bashio::config 'smtp_sender_pass')
                if [ -n "$SMTP_USER" ]; then
                    echo "smtp-sender-user: \"$SMTP_USER\""
                    echo "smtp-sender-pass: \"$SMTP_PASS\""
                fi
            fi
        fi
    fi
    
} > "$CONFIG_FILE"

bashio::log.info "Configuration generated at $CONFIG_FILE"
bashio::log.info "Starting ntfy server..."

# Start ntfy with the serve command and any additional arguments
exec /usr/local/bin/ntfy serve --config="$CONFIG_FILE" "$@"
