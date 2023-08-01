#!/usr/bin/env bash

cat <<-WELCOME_MESSAGE

	PocketBase is under the MIT License.

	> PocketBase version: ${POCKETBASE_VERSION}
	> Datadir: /pb_data $(stat -c '(%u:%g with %A)' /pb_data)
	> User: $(id)

WELCOME_MESSAGE

POCKETBASE_FLAGS=()

test -n "${POCKETBASE_DEBUG}"   			&& POCKETBASE_FLAGS+=("--debug")
test -n "${POCKETBASE_CORS}"    			&& POCKETBASE_FLAGS+=("--origins=${POCKETBASE_CORS}")
test -n "${POCKETBASE_ENCRYPTION_KEY}"  	&& POCKETBASE_FLAGS+=("--encryptionEnv=${POCKETBASE_ENCRYPTION_KEY}")

POCKETBASE_DIR_FLAGS=()

test -n "${POCKETBASE_DATA_DIR}"           && POCKETBASE_DIR_FLAGS+=("--dir=${POCKETBASE_DATA_DIR}")
test -n "${POCKETBASE_MIGRATION_DIR}"      && POCKETBASE_DIR_FLAGS+=("--migrationsDir=${POCKETBASE_MIGRATION_DIR}")
test -n "${POCKETBASE_PUBLIC_DIR}"         && POCKETBASE_DIR_FLAGS+=("--publicDir=${POCKETBASE_PUBLIC_DIR}")

if [ ! "${POCKETBASE_ENCRYPTION_KEY:-}" ]; then
    POCKETBASE_ENCRYPTION_KEY="$(echo -n $RANDOM | sha1sum | awk '{print $1}')"
    export POCKETBASE_ENCRYPTION_KEY
    test -n "${POCKETBASE_ENCRYPTION_KEY}" && POCKETBASE_FLAGS+=("--encryptionEnv=${POCKETBASE_ENCRYPTION_KEY}")
  	cat <<-SECRET_WARNING
		WARNING: POCKETBASE ENCRYPTION_KEY variable was not set or was not string!
		Secret key was automatically generated: ${POCKETBASE_ENCRYPTION_KEY}
		Please note down this value and set the POCKETBASE_ENCRYPTION_KEY within your deployment to avoid loosing access to your data!
		SECRET_WARNING
    echo " "
fi

echo "> Preparing directories..."
mkdir -p \
"${POCKETBASE_DATA_DIR}" \
"${POCKETBASE_PUBLIC_DIR}" \
"${POCKETBASE_MIGRATION_DIR}" \
&& ls /pb_data
echo " "

echo "> Starting PocketBase..."
echo ">> Please note down this value and set the POCKETBASE_ENCRYPTION_KEY within your deployment to avoid loosing access to your data!"
echo ">> Secret key: ${POCKETBASE_ENCRYPTION_KEY}"
set -x
pocketbase serve \
"${POCKETBASE_FLAGS[@]}" \
"${POCKETBASE_DIR_FLAGS[@]}" \
--http="${POCKETBASE_HOST}:${POCKETBASE_PORT}"
"$@"